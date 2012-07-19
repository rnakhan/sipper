#include "SipperProxyQueue.h"
#include <errno.h>

bool mbLogFlag = true;

SipperProxyQueue::SipperProxyQueue(bool p_flowControlEnabled, unsigned int p_highWaterMark, 
                 unsigned int p_lowWaterMark)
{
   t_EventQueueNode     *pNewNode;

   pthread_mutex_init(&tEventQueueMutex,  NULL);

   pthread_cond_init(&waitingFeederCond, NULL);
   pthread_cond_init(&waitingConsumerCond,NULL);

   ptHeadPtr = ptTailPtr = NULL;
   iQueueCount = 0;

   flowControlEnabled = p_flowControlEnabled;
   highWaterMark      = p_highWaterMark;
   lowWaterMark       = p_lowWaterMark;

   ptFreeList = NULL;

   for(iFreeNodes = 0; iFreeNodes < highWaterMark; iFreeNodes++)
   {
      pNewNode = new t_EventQueueNode;

      pNewNode->ptNextNode = ptFreeList;

      ptFreeList = pNewNode;
   }

   bQueueStopped       = false;    // Queue stopped indicator.

   sleepingFeeders = 0;
   sleepingConsumers = 0;

   waitingFeeders = 0;
   waitingConsumers = 0;

   minFeeder = -1;
   minConsumer = -1;
   _cleanupFunc = NULL;
}

SipperProxyQueue::~SipperProxyQueue()
{
   stopQueue();

   int oldstate;
   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);
   pthread_mutex_lock(&tEventQueueMutex);

   //Queue should be destroyed after all its messages were given out. Since in 
   //dequeue we are leaving out. I removed the check of queuecount != 0 here.
   while (sleepingFeeders || sleepingConsumers || 
          waitingFeeders || waitingConsumers)
   {
      pthread_cond_wait(&waitingConsumerCond, &tEventQueueMutex);
   }

   if(iQueueCount != 0)
   {
   }

   t_EventQueueNodePtr currNode, nextNode;
   currNode = ptFreeList;

   for(unsigned int idx = 0; (idx < highWaterMark) && (currNode != NULL); idx++)
   {
      //NULL check is reqd as not all the nodes were captured back to freelist.
      //Some mem leaks because dequeue returns error even there are messages in 
      //queue to process.
      nextNode = currNode->ptNextNode;
      delete currNode;
      currNode = nextNode;
   }

   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);

   pthread_mutex_destroy(&tEventQueueMutex);
   pthread_cond_destroy(&waitingFeederCond);
   pthread_cond_destroy(&waitingConsumerCond);

}

unsigned int SipperProxyQueue::queueSize(void)
{
   unsigned int     iRetVal;

   int oldstate;
   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);
   pthread_mutex_lock(&tEventQueueMutex);
   iRetVal = iQueueCount;
   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);

   return iRetVal;
}

void SipperProxyQueue::stopQueue(void)
{
   int oldstate;
   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);
   pthread_mutex_lock(&tEventQueueMutex);

   if(bQueueStopped)
   {
      pthread_mutex_unlock(&tEventQueueMutex);
      pthread_setcancelstate(oldstate, NULL);
      return;
   }

   bQueueStopped = true;

   pthread_cond_broadcast(&waitingFeederCond);
   pthread_cond_broadcast(&waitingConsumerCond);

   for(unsigned int idx = 0; idx < MAX_QUEUE_THR; idx++)
   {
      if(feederData[idx].count)
      {
         pthread_cond_signal(&feederData[idx].condition);
      }

      if(consumerData[idx].count)
      {
         pthread_cond_signal(&consumerData[idx].condition);
      }
   }

   while(ptHeadPtr != NULL)
   {
      t_EventQueueNodePtr currNode = ptHeadPtr;
      ptHeadPtr  = ptHeadPtr->ptNextNode;
      iQueueCount--;

      if(_cleanupFunc != NULL)
      {
         _cleanupFunc(currNode->_queueData);
      }

      if(iFreeNodes < highWaterMark)
      {
         currNode->ptNextNode = ptFreeList;
         ptFreeList = currNode;

         iFreeNodes++;
      }
      else
      {
         delete currNode;
      }

      if(ptHeadPtr == NULL)
      {
         ptTailPtr = NULL;
      }
   }

   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);
}

bool SipperProxyQueue::isQueueStopped(void)
{
   bool        ret;

   int oldstate;
   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);

   pthread_mutex_lock(&tEventQueueMutex);
   ret = bQueueStopped;
   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);

   return ret;
}

unsigned int SipperProxyQueue::eventEnqueue(SipperProxyQueueData *indata)
{
   return eventEnqueueBlk(indata, 1);
}

unsigned int SipperProxyQueue::eventDequeue(SipperProxyQueueData *outdata, unsigned int timeout, 
                                   bool blockFlag)
{
   return eventDequeueBlk(outdata, 1, timeout, blockFlag);
}

unsigned int SipperProxyQueue::eventEnqueueBlk(SipperProxyQueueData *indata, unsigned int count)
{
   int oldstate;

   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);
   pthread_mutex_lock(&tEventQueueMutex);

   if(bQueueStopped == true)
   {
      pthread_mutex_unlock(&tEventQueueMutex);
      pthread_setcancelstate(oldstate, NULL);
      return 0;
   }

   while(sleepingFeeders == MAX_QUEUE_THR && bQueueStopped == false)
   {
      waitingFeeders++;
      pthread_cond_wait(&waitingFeederCond, &tEventQueueMutex);
      waitingFeeders--;
   }

   unsigned int ret = 0;
   t_EventQueueNodePtr currNode = NULL;

   int feederIdx = -1;

   do
   {
      if(bQueueStopped == true)
      {
         break;
      }

      for(; ret < count; ret++)
      {
         if(ptFreeList != NULL)
         {
            currNode = ptFreeList;
            ptFreeList  = ptFreeList->ptNextNode;
            iFreeNodes--;
         }
         else
         {
            if(flowControlEnabled == false)
            {
               currNode = new t_EventQueueNode;
            }
            else
            {
               break;
            }
         }
   
         currNode->_queueData = indata[ret];
         currNode->ptNextNode = NULL;

         if(ptHeadPtr == NULL)
         {
            ptTailPtr = ptHeadPtr = currNode;
         }
         else
         {
            ptTailPtr->ptNextNode = currNode;
            ptTailPtr = currNode;
         }

         iQueueCount++;
      }

      if(ret == count)
      {
         break;
      }

      if(feederIdx == -1)
      {
         feederIdx = _getFreeThr(feederData);
      }

      if((count - ret) >= highWaterMark)
      {
         feederData[feederIdx].count = highWaterMark;
      }
      else
      {
         feederData[feederIdx].count = count - ret;
      }

      if(minFeeder != -1)
      {
         if(feederData[minFeeder].count > feederData[feederIdx].count)
         {
            minFeeder = feederIdx;
         }
      }
      else
      {
         minFeeder = feederIdx;
      }

      //Queue is Full.

      if(sleepingConsumers)
      {
         int locid = _calculateMax(consumerData);

         pthread_cond_signal(&consumerData[locid].condition);
      }

      sleepingFeeders++;
      pthread_cond_wait(&feederData[feederIdx].condition, &tEventQueueMutex);
      sleepingFeeders--;
   }while(1);

   if(feederIdx != -1)
   {
      feederData[feederIdx].count = 0;

      if(minFeeder == feederIdx)
      {
         minFeeder = _calculateMin(feederData);
      }
   }

   if(sleepingFeeders)
   {
      if((feederData[minFeeder].count <= iFreeNodes) ||
         (iQueueCount <= lowWaterMark))
      {
         pthread_cond_signal(&feederData[minFeeder].condition);
      }
   }

   if(sleepingConsumers)
   {
      if(consumerData[minConsumer].count <= iQueueCount)
      {
         pthread_cond_signal(&consumerData[minConsumer].condition);
      }
   }

   if(waitingFeeders)
   {
      pthread_cond_signal(&waitingFeederCond);
   }

   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);
   return ret;
}

unsigned int SipperProxyQueue::eventDequeueBlk(SipperProxyQueueData *outdata, unsigned int count, 
                                      unsigned int timeout, bool blockFlag)
{
   int oldstate;

   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);
   pthread_mutex_lock(&tEventQueueMutex);

   while(sleepingConsumers == MAX_QUEUE_THR && bQueueStopped == false)
   {
      waitingConsumers++;
      pthread_cond_wait(&waitingConsumerCond, &tEventQueueMutex);
      waitingConsumers--;
   }

   unsigned int ret = 0;
   t_EventQueueNodePtr currNode = NULL;

   int consumerIdx = -1;

   int alreadyTimedOut = 0; 
   int timeCalculated = 0;
   struct timespec WaitTime;

   do
   {
      //Logically this if condition should not be there. When the queue is 
      //stopped still deque should be successful till there are messages held in
      //queue. This condition will raise memory leak as consumers cant get the 
      //messages. Only reason I thought of why this condition was added is 
      //during shutdown we want the consumer to come out quickly- Suriya.
      //Now a CleanupFunction registeration is added to take care of the memory 
      //leak caused because of this condition.
      if(bQueueStopped == true)
      {
         break;
      }

      for(; ret < count; ret++)
      {
         if(ptHeadPtr != NULL)
         {
            currNode = ptHeadPtr;
            ptHeadPtr  = ptHeadPtr->ptNextNode;
            iQueueCount--;

            outdata[ret] = currNode->_queueData;

            if(iFreeNodes < highWaterMark)
            {
               currNode->ptNextNode = ptFreeList;
               ptFreeList = currNode;

               iFreeNodes++;
            }
            else
            {
               delete currNode;
            }

            if(ptHeadPtr == NULL)
            {
               ptTailPtr = NULL;
            }
         }
         else
         {
            break;
         }
      }

      if(ret == count || blockFlag == false)
      {
         break;
      }

      if(bQueueStopped == true)
      {
         pthread_cond_broadcast(&waitingConsumerCond);
         break;
      }

      if(consumerIdx == -1)
      {
         consumerIdx = _getFreeThr(consumerData);
      }

      if((count - ret) >= highWaterMark)
      {
         consumerData[consumerIdx].count = highWaterMark;
      }
      else
      {
         consumerData[consumerIdx].count = count - ret;
      }

      if(minConsumer != -1)
      {
         if(consumerData[minConsumer].count > consumerData[consumerIdx].count)
         {
            minConsumer = consumerIdx;
         }
      }
      else
      {
         minConsumer = consumerIdx;
      }

      //Queue is Empty.

      if(sleepingFeeders)
      {
         int locid = _calculateMax(feederData);

         pthread_cond_signal(&feederData[locid].condition);
      }

      if(alreadyTimedOut)
      {
         break;
      }

      sleepingConsumers++;

      if(timeout == 0)
      {
         pthread_cond_wait(&consumerData[consumerIdx].condition, 
                           &tEventQueueMutex);
      }
      else
      {
         if(timeCalculated == 0)
         {
            struct timeval currTime;

            gettimeofday(&currTime, NULL);

            WaitTime.tv_sec = currTime.tv_sec;
            WaitTime.tv_nsec = (currTime.tv_usec * 1000);

            WaitTime.tv_sec += (timeout / 1000);
            long millisec = timeout % 1000;
            WaitTime.tv_nsec += (millisec * 1000000);

            if(WaitTime.tv_nsec >= 1000000000L)
            {
               WaitTime.tv_nsec -= 1000000000L;
               WaitTime.tv_sec++;
            }

            timeCalculated = 1;
         }

         if(pthread_cond_timedwait(&consumerData[consumerIdx].condition,
                                &tEventQueueMutex, &WaitTime) == ETIMEDOUT)
         {
            alreadyTimedOut = 1;
         }
      }

      sleepingConsumers--;
   }while(1);

   if(consumerIdx != -1)
   {
      consumerData[consumerIdx].count = 0;

      if(minConsumer == consumerIdx)
      {
         minConsumer = _calculateMin(consumerData);
      }
   }

   if(sleepingFeeders)
   {
      if((feederData[minFeeder].count <= iFreeNodes) ||
         (iQueueCount <= lowWaterMark))
      {
         pthread_cond_signal(&feederData[minFeeder].condition);
      }
   }

   if(sleepingConsumers)
   {
      if(consumerData[minConsumer].count <= iQueueCount)
      {
         pthread_cond_signal(&consumerData[minConsumer].condition);
      }
   }

   if(waitingConsumers)
   {
      pthread_cond_signal(&waitingConsumerCond);
   }

   pthread_mutex_unlock(&tEventQueueMutex);
   pthread_setcancelstate(oldstate, NULL);
   return ret;
}

int SipperProxyQueue::_getFreeThr(QueueThrData *indata)
{
   for(unsigned int idx = 0; idx < MAX_QUEUE_THR; idx++)
   {
      if(indata[idx].count == 0)
      {
         return idx;
      }
   }

   //Major Error.
   return -1;
}

int SipperProxyQueue::_calculateMax(QueueThrData *indata)
{
   unsigned int current_max = indata[0].count;
   int ret = 0;

   for(unsigned int idx = 1; idx < MAX_QUEUE_THR; idx++)
   {
      if(indata[idx].count > current_max)
      {
         ret = idx;
         current_max = indata[idx].count;
      }
   }

   return ret;
}

int SipperProxyQueue::_calculateMin(QueueThrData *indata)
{
   unsigned int current_min = indata[0].count;
   int ret = 0;

   for(unsigned int idx = 1; idx < MAX_QUEUE_THR; idx++)
   {
      if(indata[idx].count < current_min)
      {
         ret = idx;
         current_min = indata[idx].count;
      }
   }

   return ret;
}

void SipperProxyQueue::registerCleanupFunc(CleanupFunc inFunc)
{
   int oldstate;
   pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);

   pthread_mutex_lock(&tEventQueueMutex);
   _cleanupFunc = inFunc;
   pthread_mutex_unlock(&tEventQueueMutex);

   pthread_setcancelstate(oldstate, NULL);
}

void SipperProxyQueue::setName(const std::string &name)
{
   _name = name;
}

const std::string & SipperProxyQueue::getName() const
{
   return _name;
}

std::string SipperProxyQueue::toLog(unsigned int tabCount) const
{
   char tabs[20];

   for(unsigned int idx = 0; idx < tabCount; idx++)
   {
      tabs[idx] = '\t';
   }

   tabs[tabCount] = '\0';

   std::string ret = tabs;
   ret += "<Queue Name=\"" + _name + "\">\n";

   pthread_mutex_lock(const_cast<pthread_mutex_t *>(&tEventQueueMutex));

   char data[1000];
   sprintf(data, "%s\t<Detail MsgCount=\"%d\" FreeCount=\"%d\"/>\n"
                 "%s\t<Waiting Feeders=\"%d\" Consumers=\"%d\"/>\n"
                 "%s\t<Sleeping Feeders=\"%d\" Consumers=\"%d\"/>\n"
                 "%s\t<Stat FlowCtrl=\"%d\" StopStatus=\"%d\"/>\n"
                 "%s\t<Limits Low=\"%d\" High=\"%d\"/>\n"
                 "%s\t<ActiveFeeder Feeder=\"%d\" MsgCount=\"%d\"/>\n"
                 "%s\t<ActiveConsumer Consumer=\"%d\" MsgCount=\"%d\"/>\n",
           tabs, iQueueCount, iFreeNodes,
           tabs, waitingFeeders, waitingConsumers,
           tabs, sleepingFeeders, sleepingConsumers,
           tabs, flowControlEnabled, bQueueStopped, 
           tabs, lowWaterMark, highWaterMark,
           tabs, minFeeder, feederData[0].count, 
           tabs, minConsumer, consumerData[0].count);

   pthread_mutex_unlock(const_cast<pthread_mutex_t *>(&tEventQueueMutex));

   ret += data;

   ret += tabs;
   ret += "</Queue>\n";

   return ret;
}

