#include "SipperMediaLogger.h"
LOG("SipperMedia");
#include "SipperMedia.h"
#include "SipperMediaListener.h"
#include "SipperMediaController.h"
#include "SipperMediaPortMgr.h"

#ifndef INADDR_ANY
#define INADDR_ANY -1
#endif

#ifndef INADDR_NONE
#define INADDR_NONE -1
#endif

SipperMedia * SipperMedia::createMedia(ParamMap &params)
{
   SipperMedia *ret = NULL;

   std::string type = params["MEDIATYPE"];

   if(type == "RTP")
   {
      unsigned short recvport = (unsigned short)atoi(params["RECVPORT"].c_str());

      try
      {
         if(params.find("RECVIP") != params.end())
         {
            std::string recvip = params["RECVIP"];
            ret = new SipperRTPMedia(inet_addr(recvip.c_str()), recvport);
         }
         else
         {
            ret = new SipperRTPMedia(htonl(INADDR_ANY), recvport);
         }
      }
      catch(...)
      {
         return NULL;
      }
   }
   
   return ret;
}

void SipperMedia::sendEvent(const std::string &inevt)
{
   char event[200];

   sprintf(event, "TYPE=EVENT;MEDIAID=%d;%s", id, inevt.c_str());
   controller->sendEvent(event);
}

SipperRTPMedia::SipperRTPMedia(unsigned int ip, unsigned short recvport)
{
   _sendPort = 0;
   _sendIP = 0;
   _keepAliveIntervalInSec = 0;
   _portFromMgrFlag = false;
   lastDtmfTimestamp = 0;
   _lastKeepAliveSentTime.tv_sec = 0;
   _lastKeepAliveSentTime.tv_usec = 0;

   if((_recvSocket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
   {
     logger.logMsg(ERROR_FLAG, 0, "Socket creation error. [%s]\n", strerror(SipperMediaPortable::getErrorCode()));
      exit(1);
   }

   u_int flagOn = 1;
#ifndef __UNIX__
   setsockopt(_recvSocket, SOL_SOCKET, SO_REUSEADDR, (const char *)&flagOn, sizeof(flagOn));
#else
   setsockopt(_recvSocket, SOL_SOCKET, SO_REUSEADDR, &flagOn, sizeof(flagOn));
#endif

   if(recvport == 0)
   {
      unsigned int retry = 0;
      SipperMediaPortMgr &portMgr = SipperMediaPortMgr::getInstance();
      while(true)
      {
         retry++;
         if(retry > 3000)
         {
            logger.logMsg(ERROR_FLAG, 0, "No freeport from PortMgr after multiple retries.\n");
            SipperMediaListener::disconnectSocket(_recvSocket);
            throw 1;
         }

         if(portMgr.getPort(recvport) == -1)
         {
            logger.logMsg(ERROR_FLAG, 0, "Error getting freeport from PortMgr.\n");
            SipperMediaListener::disconnectSocket(_recvSocket);
            throw 1;
         }

         struct sockaddr_in serv_addr;

         memset(&serv_addr, 0, sizeof(sockaddr_in));

         serv_addr.sin_family = AF_INET;
         serv_addr.sin_addr.s_addr = ip;
         serv_addr.sin_port = htons(recvport);

         if(bind(_recvSocket, (sockaddr *)&serv_addr, sizeof(sockaddr_in)) < 0)
         {
            logger.logMsg(ERROR_FLAG, 0, 
                          "Error binding port[%d] retrying. [%s]\n", recvport,
                          strerror(SipperMediaPortable::getErrorCode()));
            portMgr.releasePort(recvport);
            continue;
         }

         _portFromMgrFlag = true;

         break;
      }
   }
   else
   {
     struct sockaddr_in serv_addr;

     memset(&serv_addr, 0, sizeof(sockaddr_in));

     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = ip;
     serv_addr.sin_port = htons(recvport);

     if(bind(_recvSocket, (sockaddr *)&serv_addr, sizeof(sockaddr_in)) < 0)
     {
        logger.logMsg(ERROR_FLAG, 0, "Error binding listener. [%s]\n", strerror(SipperMediaPortable::getErrorCode()));
        SipperMediaListener::disconnectSocket(_recvSocket);
        throw 1;
     }
   }

   SipperMediaListener::setNonBlocking(_recvSocket);

   lastSentHeader.setVersion(2);
   lastSentHeader.setPadding(0);
   lastSentHeader.setExtension(0);
   lastSentHeader.setCSRCCount(0);
   lastSentHeader.setMarker(0);
   lastSentHeader.setTimeStamp(160);
   lastSentHeader.setSequence(160);
   lastSentHeader.setSSRC(0x5678);
}

SipperRTPMedia::~SipperRTPMedia()
{
   clearCodecs();

   if(_portFromMgrFlag)
   {
      SipperMediaPortMgr &portMgr = SipperMediaPortMgr::getInstance();
      struct sockaddr_in serv_addr;

      memset(&serv_addr, 0, sizeof(sockaddr_in));
#ifdef __UNIX__
      socklen_t len = sizeof(struct sockaddr_in);
#else
      int len = sizeof(struct sockaddr_in);
#endif

      if(getsockname(_recvSocket, (sockaddr *)&serv_addr, &len) < 0)
      {
         logger.logMsg(ERROR_FLAG, 0, "Error getting sockinfo. [%s]\n", strerror(SipperMediaPortable::getErrorCode()));
         SipperMediaListener::disconnectSocket(_recvSocket);
         return;
      }

      unsigned short recvport = ntohs(serv_addr.sin_port);

      portMgr.releasePort(recvport);
   }

   SipperMediaListener::disconnectSocket(_recvSocket);
}

void SipperRTPMedia::setReadFd(fd_set &readfds, int &maxfd)
{
   FD_SET(_recvSocket, &readfds);
   if(_recvSocket > maxfd) maxfd = _recvSocket;

   return;
}

void SipperRTPMedia::checkData(struct timeval &currtime, fd_set &readfds)
{
   if(FD_ISSET(_recvSocket, &readfds))
   {
      //Read the RTP packet and give to codecs.
      unsigned char buf[4000];
      struct sockaddr_in client_addr;

      memset(&client_addr, 0, sizeof(sockaddr_in));
#ifdef __UNIX__
      socklen_t clilen = sizeof(client_addr);
#else
      int clilen = sizeof(client_addr);
#endif
      int len = 0;

      if((len = recvfrom(_recvSocket, buf, 4000, 0, (struct sockaddr *)&client_addr, &clilen)) <= 0)
      {
         return;
      }

      if(len < 12)
      {
         return;
      }

      SipperMediaRTPHeader incomingHeader;
      unsigned int tmpint;
      memcpy(&tmpint, buf, 4); 
      incomingHeader.first = ntohl(tmpint);
      memcpy(&tmpint, buf + 4, 4);
      incomingHeader.timestamp = ntohl(tmpint);
      memcpy(&tmpint, buf + 8, 4);
      incomingHeader.ssrc = ntohl(tmpint);

      if(incomingHeader.getVersion() != 2)
      {
         return;
      }

      if(len < (12 + (incomingHeader.getCSRCCount() * 4)))
      {
         return;
      }

      lastRecvHeader = incomingHeader;

      switch(_mediaStatus)
      {
         case SENDONLY:
         case INACTIVE:
         {
            return;
         }
      }

      unsigned char *payload = buf + (12 + (incomingHeader.getCSRCCount() * 4));
      unsigned int payloadlen = len - (12 + (incomingHeader.getCSRCCount() * 4));

      int payloadnum = incomingHeader.getPayloadNum();

      SipperMediaCodecMapIt it = _codecMap.find(payloadnum);

      if(it != _codecMap.end())
      {
         SipperMediaCodec *currcodec = it->second;
         currcodec->processReceivedRTPPacket(currtime, payload, payloadlen);
      }
   }
}

void SipperRTPMedia::sendRTPPacket(SipperMediaRTPHeader &header, unsigned char *dataptr, unsigned int len)
{
   lastSentHeader = header;

   unsigned char data[1000];
   int tmp = lastSentHeader.first;
   tmp = htonl(tmp);
   memcpy(data, &tmp, 4);
   tmp = lastSentHeader.timestamp;
   tmp = htonl(tmp);
   memcpy(data + 4, &tmp, 4);
   tmp = lastSentHeader.ssrc;
   tmp = htonl(tmp);
   memcpy(data + 8, &tmp, 4);

   int csrccount = lastSentHeader.getCSRCCount();
   int offset = 12;
   for(int idx = 0; idx < csrccount; idx++, offset += 4)
   {
      tmp = lastSentHeader.csrc[idx];
      tmp = htonl(tmp);
      memcpy(data + offset, &tmp, 4);
   }

   memcpy(data + offset, dataptr, len);
   offset += len;

   struct sockaddr_in cli_addr;
   memset(&cli_addr, 0, sizeof(sockaddr_in));

   cli_addr.sin_family = AF_INET;
   cli_addr.sin_addr.s_addr = _sendIP;
   cli_addr.sin_port = htons(_sendPort);

   if(_sendIP != 0 && _sendPort != 0)
   {
      sendto(_recvSocket, data, offset, 0, (struct sockaddr *) &cli_addr,
              sizeof(sockaddr_in));
   }
}

void SipperRTPMedia::handleTimer(struct timeval &currtime)
{
   if((_keepAliveIntervalInSec > 0) && 
      ((_mediaStatus == INACTIVE) || (_mediaStatus == RECVONLY)))
   {
      if(_lastKeepAliveSentTime.tv_sec + _keepAliveIntervalInSec <= currtime.tv_sec)
      {
         _lastKeepAliveSentTime = currtime;
         struct sockaddr_in cli_addr;
         memset(&cli_addr, 0, sizeof(sockaddr_in));

         cli_addr.sin_family = AF_INET;
         cli_addr.sin_addr.s_addr = _sendIP;
         cli_addr.sin_port = htons(_sendPort);

         if(_sendIP != 0 && _sendPort != 0)
         {
            int data = 0;
            sendto(_recvSocket, &data, sizeof(int), 0, 
                   (struct sockaddr *) &cli_addr, sizeof(sockaddr_in));
         }
      }
   }

   if(_mediaStatus == INACTIVE)
   {
      return;
   }

   if((_mediaStatus == SENDRECV) || (_mediaStatus == SENDONLY))
   {
      for(SipperMediaCodecMapIt it = _codecMap.begin(); it != _codecMap.end(); ++it)
      {
         SipperMediaCodec *currcodec = it->second;

         currcodec->handleTimer(currtime);
      }
   }

   if((_mediaStatus == SENDRECV) || (_mediaStatus == RECVONLY))
   {
      for(SipperMediaCodecMapIt it = _codecMap.begin(); it != _codecMap.end(); ++it)
      {
         SipperMediaCodec *currcodec = it->second;

         currcodec->checkActivity(currtime);
      }
   }
}

std::string SipperRTPMedia::setProperty(ParamMap &params)
{
   ParamMapCIt it = params.find("KEEPALIVE");

   if(it != params.end())
   {
      _keepAliveIntervalInSec = atoi(it->second.c_str());

      if(_keepAliveIntervalInSec > 300) _keepAliveIntervalInSec = 300;
   }

   return "RESULT=Success";
}

std::string SipperRTPMedia::setSendInfo(ParamMap &params)
{
   std::string sendIP = params["SENDIP"];
   std::string sendPort = params["SENDPORT"];

   short sport = (short) atoi(sendPort.c_str());
   if(sport == 0)
   {
      return "RESULT=Error;REASON=Invalid port";
   }

   unsigned int sip = inet_addr(sendIP.c_str());

   if(sip == INADDR_NONE)
   {
      return "RESULT=Error;REASON=Invalid IP";
   }

   _sendPort = sport;
   _sendIP = sip;

   return "RESULT=Success";
}

std::string SipperRTPMedia::setMediaStatus(const std::string &status)
{
   if(status == "INACTIVE")
   {
      _mediaStatus = INACTIVE;
   }
   else if(status == "SENDONLY")
   {
      _mediaStatus = SENDONLY;
   }
   else if(status == "RECVONLY")
   {
      _mediaStatus = RECVONLY;
   }
   else if(status == "SENDRECV")
   {
      _mediaStatus = SENDRECV;
   }
   else
   {
         return "RESULT=Error";
   }

   return "RESULT=Success";

}

std::string SipperRTPMedia::getRecvInfo()
{
   struct sockaddr_in serv_addr;

   memset(&serv_addr, 0, sizeof(sockaddr_in));
#ifdef __UNIX__
   socklen_t len = sizeof(struct sockaddr_in);
#else
   int len = sizeof(struct sockaddr_in);
#endif

   if(getsockname(_recvSocket, (sockaddr *)&serv_addr, &len) < 0)
   {
     logger.logMsg(ERROR_FLAG, 0, "Error getting sockinfo. [%s]\n", strerror(SipperMediaPortable::getErrorCode()));
      return "RECVIP=0.0.0.0;RECVPORT=0";
   }

   char result[100];
   if(serv_addr.sin_addr.s_addr == htonl(INADDR_ANY))
   {
      sprintf(result, "RECVIP=%s;RECVPORT=%d", controller->getIp().c_str(), ntohs(serv_addr.sin_port));
   }
   else
   {
      sprintf(result, "RECVIP=%s;RECVPORT=%d", inet_ntoa(serv_addr.sin_addr), ntohs(serv_addr.sin_port));
   }

   return result;
}

std::string SipperRTPMedia::clearCodecs()
{
   for(SipperMediaCodecMapIt it = _codecMap.begin(); it != _codecMap.end(); ++it)
   {
      SipperMediaCodec *currcodec = it->second;
      delete currcodec;
   }

   _codecMap.clear();
   return "RESULT=Success";
}

std::string SipperRTPMedia::addCodecs(ParamMap &params)
{
   int ourpayload  = atoi(params["RECVPAYLOADNUM"].c_str());
   int peerpayload = atoi(params["SENDPAYLOADNUM"].c_str());
   std::string type = params["CODEC"];
   std::string sendFile = params["SENDFILE"];
   std::string recvFile = params["RECVFILE"];

   SipperMediaCodec *currcodec = _codecMap[ourpayload];
   if(currcodec != NULL)
   {
      delete currcodec;
   }
   _codecMap.erase(ourpayload);

   if(type == "G711U")
   {
      currcodec = new SipperMediaG711Codec(SipperMediaG711Codec::G711U, sendFile, recvFile);
   }
   else if(type == "G711A")
   {
      currcodec = new SipperMediaG711Codec(SipperMediaG711Codec::G711A, sendFile, recvFile);
   }
   else if(type == "DTMF")
   {
      currcodec = new SipperMediaDTMFCodec(sendFile, recvFile);
   }
   else
   {
      return "RESULT=Error;REASON=UnknownType";
   }

   currcodec->recvPayloadNum = ourpayload;
   currcodec->sendPayloadNum = peerpayload;
   currcodec->_media = this;

   _codecMap[ourpayload] = currcodec;

   return "RESULT=Success";
}

std::string SipperRTPMedia::sendDtmf(ParamMap &params)
{
   for(SipperMediaCodecMapIt it = _codecMap.begin(); it != _codecMap.end(); ++it)
   {
      SipperMediaCodec *currcodec = it->second;

      SipperMediaDTMFCodec *dtmfcodec = dynamic_cast<SipperMediaDTMFCodec *>(currcodec);

      if(dtmfcodec != NULL)
      {
         dtmfcodec->sendDtmf(params["DTMFCOMMAND"]);
         return "RESULT=Success";
      }
   }

   return "RESULT=Error;REASON=DTMF not negotiated";
}
