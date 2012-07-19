#ifndef __SIPPER_PROXY_QUEUE_H__
#define __SIPPER_PROXY_QUEUE_H__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/uio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <signal.h>
#include <pthread.h>
#include <string>

#define MAX_QUEUE_THR 1

struct SipperProxyQueueData
{
   void *data;
   int type;
   int extraInfo;
   int length;

   SipperProxyQueueData() :
      data(NULL),
      type(0),
      extraInfo(0),
      length(0)
   {
   }
};

/*
** Event Queue Node Strcture.
*/
typedef struct _t_EventQueueNode
{
   SipperProxyQueueData _queueData;
   struct _t_EventQueueNode *ptNextNode;       // Ptr to next node.

}t_EventQueueNode, *t_EventQueueNodePtr;

typedef void (*CleanupFunc)(SipperProxyQueueData data);

class SipperProxyQueue 
{
   private:

      class QueueThrData
      {
         public:
      
            pthread_cond_t condition;
            unsigned int count;

            QueueThrData()
            {
               pthread_cond_init(&condition, NULL);
               count = 0;
            }

            ~QueueThrData()
            {
               pthread_cond_destroy(&condition);
            }
      }; 

      unsigned int        iQueueCount;            // Event in the queue.

      t_EventQueueNodePtr ptHeadPtr;              // Ptr to head of event list.
      t_EventQueueNodePtr ptTailPtr;              // Ptr to tail of event list.
  
      t_EventQueueNodePtr ptFreeList;             // List of free nodes.
      unsigned int        iFreeNodes;             // No. of nodes in free list.
  
      pthread_mutex_t     tEventQueueMutex;       // Mutex
  
      pthread_cond_t      waitingFeederCond;
      pthread_cond_t      waitingConsumerCond;
  
      bool                bQueueStopped;         // Queue stopped indicator.
  
      bool                flowControlEnabled;    // Flag indicating flow control.
      unsigned int        lowWaterMark;          // Low water mark.
      unsigned int        highWaterMark;         // High water mark.
  
      unsigned int waitingFeeders;
      unsigned int waitingConsumers;
  
      unsigned int sleepingFeeders;
      unsigned int sleepingConsumers;
  
      QueueThrData feederData[MAX_QUEUE_THR];
      QueueThrData consumerData[MAX_QUEUE_THR];

      int minFeeder;
      int minConsumer;

      int _getFreeThr(QueueThrData *);
      int _calculateMax(QueueThrData *);
      int _calculateMin(QueueThrData *);
  
      CleanupFunc _cleanupFunc;

      std::string _name;

  public:
  
      SipperProxyQueue(bool flowControlEnabled    = false, 
              unsigned int highWaterMark = 512,
              unsigned int lowWaterMark  = 512);
  
      ~SipperProxyQueue();
  
      unsigned int eventEnqueue(SipperProxyQueueData *data);
      unsigned int eventEnqueueBlk(SipperProxyQueueData *data, unsigned int count);

      unsigned int eventDequeue(SipperProxyQueueData *data, unsigned int timeout, 
                                bool = true);
      unsigned int eventDequeueBlk(SipperProxyQueueData *data, unsigned int count, 
                                   unsigned int timeout, bool = true);
  
      unsigned int queueSize(void);  // Get events in the queue
      void stopQueue(void);          // Stop queue processing.
      bool isQueueStopped(void);     // Check if queue is stopped.
  
      void registerCleanupFunc(CleanupFunc);

      void setName(const std::string &name);
      const std::string &getName() const;

      std::string toLog(unsigned int tabCount) const;
};

#endif
