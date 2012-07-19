#include "SipperProxyLogger.h"
LOG("ProxyStatFile");
#include "SipperProxyStatFileDispatcher.h"
#include <sstream>

SipperProxyStatFileDispatcher::SipperProxyStatFileDispatcher(
          const std::string &file, unsigned int inRecCount, SipperProxyStatMgr *mgr) :
   SipperProxyStatDispatcher(mgr),
   _fp(NULL),
   _filename(file),
   _recCount(inRecCount),
   _currFileIdx(0),
   _currFileSize(0)
{
   if(_openFile() == -1)
   {
      return;
   }
   pthread_t thread;
   addRef();
   pthread_create(&thread, NULL, _threadStart, this);
}

SipperProxyStatFileDispatcher::~SipperProxyStatFileDispatcher()
{
   if(_fp != NULL)
   {
      fflush(_fp);
      fclose(_fp);
   }
}

int SipperProxyStatFileDispatcher::_openFile()
{
   _currFileIdx++;
   _currFileSize = 0;

   if(_fp != NULL)
   {
      fflush(_fp);
      fclose(_fp);
      _fp = NULL;
   }

   std::ostringstream strStream;
   strStream << _filename << "_" << _currFileIdx << ".smsg";

   _fp = fopen(strStream.str().c_str(), "w");
   if(_fp == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "Error opening file [%s].\n",
                    strerror(SipperProxyPortable::getErrorCode()));
      return -1;
   }
}

void SipperProxyStatFileDispatcher::_processData()
{
   while(!_queue.isQueueStopped())
   {
      fflush(_fp);
      SipperProxyQueueData inMsg[100];
      int msgCount = _queue.eventDequeueBlk(inMsg, 100, 500, true);
      bool errorFlag = false;

      for(int idx = 0; idx < msgCount; idx++)
      {
         SipperProxyRefObjHolder<SipperProxyRawMsg> holder((SipperProxyRawMsg *) (inMsg[idx].data));
         SipperProxyRawMsg *msg = holder.getObj();
         unsigned int msgLen = 0;
         char *buffer = msg->getBuf(msgLen);

         if(errorFlag) continue;

         if(fwrite(buffer, msgLen, 1, _fp) != 1)
         {
            errorFlag = true;
            logger.logMsg(ERROR_FLAG, 0, "Error writing file [%s].\n",
                          strerror(SipperProxyPortable::getErrorCode()));
            _queue.stopQueue();
         }

         _currFileSize += msgLen;

         if(_currFileSize >= _recCount)
         {
            if(_openFile() == -1)
            {
               _queue.stopQueue();
            }
         }
      }
   }

   return;
}
