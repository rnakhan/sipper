#include "SipperMediaLogger.h"
LOG("SipperMediaController");

#include "SipperMediaController.h"
#include "SipperMediaPortable.h"
#include "SipperMediaTokenizer.h"
#include "SipperMediaListener.h"
#include <set>
#include <iterator>

SipperMediaController::SipperMediaController()
{
   this->_callbackMSec = 20;
   this->_mediaSeq = 1;
   this->_shutdownFlag = false;
}

SipperMediaController::~SipperMediaController()
{
   for(SipperMediaMapIt it = _mediaMap.begin(); it != _mediaMap.end(); ++it)
   {
      SipperMedia *currMedia = it->second;
      delete currMedia;
   }
   _mediaMap.clear();
}

void SipperMediaController::handleTimeout(struct timeval *currtime, struct timeval *nextcallback)
{
   int loopcount = 0;
   while(!SipperMediaPortable::isGreater(nextcallback, currtime))
   {
      loopcount++;

      if(loopcount > 50)
      {
         logger.logMsg(WARNING_FLAG, 0, 
                       "breaking after 50. Currtime[%d][%d] Nextcallback[%d][%d]\n",
                       currtime->tv_sec, currtime->tv_usec, nextcallback->tv_sec, nextcallback->tv_usec);
         break;
      }

      for(SipperMediaMapIt it = _mediaMap.begin(); it != _mediaMap.end(); ++it)
      {
         SipperMedia *currMedia = it->second;
         currMedia->handleTimer(*currtime);
      }

      nextcallback->tv_usec += (_callbackMSec * 1000);

      if(nextcallback->tv_usec > 1000000)
      {
         nextcallback->tv_sec += (nextcallback->tv_usec / 1000000);
         nextcallback->tv_usec %= 1000000;
      }
   }
}

void SipperMediaController::handleRequest(int commandSock)
{
   struct sockaddr_in serv_addr;

   memset(&serv_addr, 0, sizeof(sockaddr_in));
#ifdef __UNIX__
   socklen_t len = sizeof(struct sockaddr_in);
#else
   int len = sizeof(struct sockaddr_in);
#endif

   if(getsockname(commandSock, (sockaddr *)&serv_addr, &len) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error getting sockinfo. [%s]\n", 
                    strerror(SipperMediaPortable::getErrorCode()));
   }
   else
   {
      _controllerIp = inet_ntoa(serv_addr.sin_addr);
      logger.logMsg(ALWAYS_FLAG, 0, 
                    "ControllerIP [%s]\n", _controllerIp.c_str());
   }

   fd_set readfds;
   struct timeval currtime;
   struct timeval nextcallback;

   SipperMediaPortable::getTimeOfDay(&currtime);
   nextcallback = currtime;

   while(!_shutdownFlag)
   {
      FD_ZERO(&readfds);
      SipperMediaPortable::getTimeOfDay(&currtime);

      handleTimeout(&currtime, &nextcallback);

      struct timeval timeout;

      if(SipperMediaPortable::isGreater(&nextcallback, &currtime))
      {
         timeout = SipperMediaPortable::getTimeDifference(&nextcallback, &currtime);
      }
      else
      {
         timeout.tv_sec = 0;
         timeout.tv_usec = (_callbackMSec * 1000);
      }

      FD_SET(commandSock, &readfds);
      int max = commandSock;

      for(SipperMediaMapIt it = _mediaMap.begin(); it != _mediaMap.end(); ++it)
      {
         SipperMedia *currMedia = it->second;
         currMedia->setReadFd(readfds, max);
      }

      int retval = select(max + 1, &readfds, NULL, NULL, &timeout);

      if(retval > 0)
      {
         SipperMediaPortable::getTimeOfDay(&currtime);

         for(SipperMediaMapIt it = _mediaMap.begin(); it != _mediaMap.end(); ++it)
         {
            SipperMedia *currMedia = it->second;
            currMedia->checkData(currtime, readfds);
         }

         if(handleCommand(commandSock, readfds) == -1)
         {
            break;
         }
      }
   }
}

void SipperMediaController::shutdown()
{
   _shutdownFlag = true;
}

int SipperMediaController::sendSocket(int sock, const void *indata, unsigned int toSend)
{
   int retVal = 0;

   fd_set write_fds;  
   char *buf = (char *)indata;

   while(toSend)
   {
      retVal = send(sock, buf, toSend, 0);

     if(retVal >= 0)
     {
        buf += retVal;
        toSend -= retVal;
        continue;
     }

     switch(SipperMediaPortable::getErrorCode())
     {
#ifdef __UNIX__
      case EINTR:
#else
      case WSAEINTR:
#endif
      {
            logger.logMsg(ERROR_FLAG, 0, 
                          "Send interrupted. [%d] Msg[%s].\n",
            sock, strerror(SipperMediaPortable::getErrorCode()));
          continue;
      }
#ifdef __UNIX__
      case EAGAIN:
#else
      case WSAEWOULDBLOCK:
#endif
      {
      }
      break;

      default:
      {
         logger.logMsg(ERROR_FLAG, 0, 
                       "Error in sending [%d] Msg[%s].\n",
                       sock, strerror(SipperMediaPortable::getErrorCode()));
         return -1;
      }
     }
         
      FD_ZERO(&write_fds);  FD_SET(sock, &write_fds);

      struct timeval time_out;

      time_out.tv_sec = 5;
      time_out.tv_usec = 0;

      logger.logMsg(WARNING_FLAG, 0, 
                    "Waiting for buffer clearup. Sock[%d].\n",
                    sock);

      retVal = select(sock + 1, NULL, &write_fds, NULL, &time_out);

      if(retVal == 0)
      {
       logger.logMsg(ERROR_FLAG, 0, 
                     "Write select timedout.\n");
         return -1;
      }
   }

   return 0;
}

int SipperMediaController::readSocket(int sock, void *buf, unsigned int toRead)
{
   char *addr = (char *)buf;
   unsigned int dataRead = 0;

   int retVal = 0;

   fd_set read_fds;  

   while(toRead)
   {
      retVal = recv(sock, addr, toRead, 0);

      if(retVal == 0)
      {
         logger.logMsg(ERROR_FLAG, 0, 
                       "Recv returned zero for[%d] Read[%d].\n", sock, dataRead);
         return -1;
      }
      else if(retVal > 0)
      {
         dataRead += retVal;
         toRead -= retVal;

         if(toRead == 0)
         {
            return 0;
         }
         else
         {
            addr += retVal;
         }

         continue;
      }
      else
      {
         switch(SipperMediaPortable::getErrorCode())
         {
#ifdef __UNIX__
            case EINTR:
#else
            case WSAEINTR:
#endif
            {
               logger.logMsg(ERROR_FLAG, 0, 
                             "Recv interrupted for [%d]. [%s]\n", 
                             sock, strerror(SipperMediaPortable::getErrorCode()));
            }
            break;

#ifdef __UNIX__
            case EWOULDBLOCK:
#else
            case WSAEWOULDBLOCK:
#endif
            {
            }
            break;

            default:
            {
               logger.logMsg(ERROR_FLAG, 0, 
                             "Recv failed for [%d]. [%s]\n", 
                             sock, strerror(SipperMediaPortable::getErrorCode()));
               return -1;
            }
         }
      }

      while(true)
      {
         FD_ZERO(&read_fds);  FD_SET(sock, &read_fds);

         struct timeval time_out;
         time_out.tv_sec = 5;
         time_out.tv_usec = 0;

         retVal = select(sock + 1, &read_fds, NULL, NULL, &time_out);

         if((retVal == -1) && (errno == EINTR))
         {
            logger.logMsg(ERROR_FLAG, 0, 
                          "Select for [%d] interrupted. [%s]\n", 
                          sock, strerror(SipperMediaPortable::getErrorCode()));
            continue;
         }

         break;
      }

      if(retVal == 0)
      {
         logger.logMsg(ERROR_FLAG, 0, 
                       "Error reading command completly. Read[%d] ToRead[%d].\n", 
                       dataRead, toRead);
         return -1;
      }

      if(retVal == -1)
      {
         logger.logMsg(ERROR_FLAG, 0, 
                       "Select failed for [%d]. [%s]\n", 
                       sock, strerror(SipperMediaPortable::getErrorCode()));
         return -1;
      }
   }

   return 0;
}

int SipperMediaController::handleCommand(int commandSock, fd_set &readfds)
{
   if(!FD_ISSET(commandSock, &readfds))
   {
      return 0;
   }
   _sock = commandSock;

   unsigned int len = 0;
   
   if(readSocket(commandSock, &len, 4) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "ReadFailed couldn't read command length.\n");
      return -1;
   }

   len = ntohl(len);
   if(len > 1000)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Very big command length.[%d]\n", len);
      return -1;
   }

   char *command = new char[len + 1];
   command[len] = '\0';
   if(readSocket(commandSock, command, len) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Couldn't read the complete command.Len[%d]\n", len);
      delete []command;
      return -1;
   }

   logger.logMsg(ALWAYS_FLAG, 0, 
                 "Processing Msg Len[%d] Command[%s]\n", len, command);

   std::string commandStr = command;
   delete []command;

   std::string resultStr = executeCommand(commandStr);

   logger.logMsg(ALWAYS_FLAG, 0, 
                 "Result Len[%d] Command[%s]\n", resultStr.size(), resultStr.c_str());

   len = resultStr.size();
   len = htonl(len);
   if(sendSocket(commandSock, &len, 4) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error sending command[%s] result len.\n", commandStr.c_str());
      return -1;
   }

   if(sendSocket(commandSock, resultStr.c_str(), resultStr.size()) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error sending command[%s] result string.\n", commandStr.c_str());
      return -1;
   };

   return 0;
}


std::string SipperMediaController::executeCommand(std::string &command)
{
   std::string delimiter = ";";
   StrSet paramSet;

   std::insert_iterator<StrSet>  inserter(paramSet, paramSet.begin());

   SipperMediaTokenizer(command, delimiter, inserter);

   ParamMap commandParams;
   for(StrSetCIt cit = paramSet.begin(); cit != paramSet.end(); ++cit)
   {
     const std::string &currParam = *cit;

     int idx = currParam.find('=');
     if(idx == -1)
     {
        logger.logMsg(ERROR_FLAG, 0, 
                      "Invalid format. Param[%s].\n", currParam.c_str());
        continue;
     }

     std::string param = currParam.substr(0, idx);
	 SipperMediaPortable::toUpper(param);
     std::string value = currParam.substr(idx + 1);
     
     commandParams[param] = value;
   }

   std::string commandstr = commandParams["COMMAND"].c_str();

   char result[500];
   if(commandstr == "CREATE MEDIA")
   {
      //Create Media.
      SipperMedia *media = SipperMedia::createMedia(commandParams);

      if(media != NULL)
      {
         media->id = _mediaSeq;
         media->controller = this;
         _mediaMap[_mediaSeq] = media;
         _mediaSeq++;
         sprintf(result, "TYPE=Result;COMMAND=%s;MEDIAID=%d;RESULT=Success;%s", 
                 commandstr.c_str(), media->id, media->getRecvInfo().c_str());
      }
      else
      {
         sprintf(result, "TYPE=Result;COMMAND=%s;RESULT=Error;REASON=Media creation failed", 
                 commandstr.c_str());
      }
      return result;
   }
   else if(commandstr == "DESTROY MEDIA")
   {
         //Destroy Media.
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         delete it->second;
         _mediaMap.erase(id);
      }
      sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Success", 
              id, commandstr.c_str());
      return result;
   }
   else if(commandstr == "MEDIA PROPERTY")
   {
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                 id, commandstr.c_str(), currMedia->setProperty(commandParams).c_str());
      }
      else
      {
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                 id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "SEND INFO")
   {
      //Set Send info.
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                 id, commandstr.c_str(), currMedia->setSendInfo(commandParams).c_str());
      }
      else
      {
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                 id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "CLEAR CODECS")
   {
      //Clear Codecs.
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         SipperRTPMedia *rtpMedia = dynamic_cast<SipperRTPMedia *>(currMedia);
         if(rtpMedia == NULL)
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Not RTP Media", 
                    id, commandstr.c_str());
         }
         else
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                    id, commandstr.c_str(), rtpMedia->clearCodecs().c_str());
         }
      }
      else
      {
        sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "ADD CODECS")
   {
      //AddCodecs.
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         SipperRTPMedia *rtpMedia = dynamic_cast<SipperRTPMedia *>(currMedia);
         if(rtpMedia == NULL)
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Not RTP Media", 
                    id, commandstr.c_str());
         }
         else
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                    id, commandstr.c_str(), rtpMedia->addCodecs(commandParams).c_str());
         }
      }
      else
      {
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                 id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "SET STATUS")
   {
      //Set status.  //Inactive, Sendonly, Recvonly, SendRecvs
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                 id, commandstr.c_str(), 
                 currMedia->setMediaStatus(commandParams["MEDIASTATUS"]).c_str());
      }
      else
      {
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                 id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "SEND DTMF")
   {
      //Send dtmf
      int id = atoi(commandParams["MEDIAID"].c_str());
      SipperMediaMapIt it = _mediaMap.find(id);
      if(it != _mediaMap.end())
      {
         SipperMedia *currMedia = it->second;
         SipperRTPMedia *rtpMedia = dynamic_cast<SipperRTPMedia *>(currMedia);
         if(rtpMedia == NULL)
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Not RTP Media", 
                    id, commandstr.c_str());
         }
         else
         {
            sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;%s", 
                    id, commandstr.c_str(), rtpMedia->sendDtmf(commandParams).c_str());
         }
      }
      else
      {
         sprintf(result, "TYPE=Result;MEDIAID=%d;COMMAND=%s;RESULT=Error;REASON=Media not found", 
                 id, commandstr.c_str());
      }

      return result;
   }
   else if(commandstr == "SHUTDOWN")
   {
      listener->shutdown();
      sprintf(result, "TYPE=Result;RESULT=SUCCESS;REASON=SHUTDOWN INITIATED");
      return result;
   }

   sprintf(result, "TYPE=Result;COMMAND=%s;RESULT=Error;REASON=Command not found", 
           commandstr.c_str());
   return result;
}

void SipperMediaController::sendEvent(const std::string &event)
{
   logger.logMsg(ALWAYS_FLAG, 0, 
                 "Event Len[%d] Event[%s]\n", event.size(), event.c_str());

   int len = event.size();
   len = htonl(len);
   if(sendSocket(_sock, &len, 4) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error sending event[%s] len.\n", event.c_str());
      return;
   }

   if(sendSocket(_sock, event.c_str(), event.size()) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error sending event[%s] string.\n", event.c_str());
      return;
   };

   return;
}
