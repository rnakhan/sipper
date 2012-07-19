#include "SipperProxyLogger.h"
LOG("ProxyMain");
#include "SipperProxy.h"
#include "SipperProxyConfig.h"
#include "SipperProxyLogMgr.h"

#include "SipperProxyRawMsg.h"

#include <netdb.h>

DnsCache::DnsCache()
{
   _lastCheckTime = time(NULL); 
}

void DnsCache::addEntry(const std::string &name, in_addr_t ip, bool removable)
{
   DnsEntry entry;
   entry.addr[0] = ip;
   entry.entryCount = 0;

   if(removable)
   {
      entry.entryTime = time(NULL);
   }
   else
   {
      entry.entryTime = -1;
   }

   _entries[name] = entry;
}

in_addr_t DnsCache::getIp(const std::string &hostname)
{
   in_addr_t ret = inet_addr(hostname.c_str());

   if(ret != -1) return ret;

   DnsMapCIt it = _entries.find(hostname);

   if(it != _entries.end())
   {
      return it->second.addr[0];
   }

   struct hostent *hentry = gethostbyname(hostname.c_str());

   if(hentry == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "Error doing DNS query [%s] [%s]\n",
                    strerror(SipperProxyPortable::getErrorCode()),
                    hostname.c_str());
      return 1;
   }

   char **currentry;
   DnsEntry entry;

   for(currentry = hentry->h_addr_list; *currentry != NULL; currentry++)
   {
      if(entry.entryCount == 5) break;

      in_addr_t netIP = 0;
      memcpy(&netIP, *currentry, sizeof(int));
      entry.addr[entry.entryCount] = netIP;

      entry.entryCount++;
   }

   if(entry.entryCount == 0)
   {
      logger.logMsg(ERROR_FLAG, 0, "No records from DNS [%s]\n",
                    hostname.c_str());
      return -1;
   }

   _entries[hostname] = entry;
   return entry.addr[0];
}

void DnsCache::checkCache()
{
   time_t now = time(NULL);
   //Check every hour and clear entries older than 2hrs.
   if((now - _lastCheckTime) < 3600) return;

   _lastCheckTime = now;

   DnsMapIt it = _entries.begin();

   while(it != _entries.end())
   {
      if(it->second.entryTime == -1)
      {
         ++it;
         continue;
      }

      if((now - it->second.entryTime) > 7200)
      {
         _entries.erase(it++);
      }
      else
      {
         ++it;
      }
   }
}

int main(int argc, char **argv)
{
#if __UNIX__
   sigignore(SIGPIPE);
#endif
   std::string configFile("SipperProxy.cfg");
   std::string logFile("SipperProxyLog.lcfg");

   for(int idx = 1; (idx + 1) < argc; idx += 2)
   {
      std::string option = argv[idx];
      std::string value = argv[idx + 1];

      if(option == "-c")
      {
        configFile = value;
      }
      else if(option == "-l")
      {
        logFile = value;
      }
   }

   LogMgr::instance().init(logFile.c_str());
   SipperProxyConfig &config = SipperProxyConfig::getInstance();
   config.loadConfigFile(configFile);

#ifndef __UNIX__
   WSADATA wsaData;
   int iResult;

   iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
   if (iResult != 0)
   {
      logger.logMsg(ERROR_FLAG, 0, "WSAStartup failed: %d\n", iResult);
      exit(1);
   }
#endif

   SipperProxy proxy;
   proxy.start();

   logger.logMsg(ALWAYS_FLAG, 0, "SipperProxy program ended.\n");
}

SipperProxy::SipperProxy() :
   _sipperOutSocket(-1),
   _sipperInSocket(-1),
   _inAddr(NULL),
   _outAddr(NULL),
   _inPort(0),
   _outPort(0),
   _numOfSipperDomain(0),
   _toSendIndex(0),
   sipperDomains(NULL)
{
   SipperProxyConfig &config = SipperProxyConfig::getInstance();

   _inStrAddr = config.getConfig("Global", "InAddr", "127.0.0.1");
   //_outStrAddr = config.getConfig("Global", "OutAddr", "");

   if(_outStrAddr == "")
   {
      _outStrAddr = _inStrAddr;
   }

   _inStrPort = config.getConfig("Global", "InPort", "5700");
   _inPort = (unsigned short) atoi(_inStrPort.c_str());
   //_outPort = (unsigned short) atoi(
                 //config.getConfig("Global", "OutPort", "0").c_str());

   if(_outPort == 0) _outPort = _inPort;

   if((_sipperInSocket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, "Socket creation error. [%s]\n",
                    strerror(SipperProxyPortable::getErrorCode()));
      exit(1);
   }

   u_int flagOn = 1;
#ifndef __UNIX__
   setsockopt(_sipperInSocket, SOL_SOCKET, SO_REUSEADDR, 
              (const char *)&flagOn, sizeof(flagOn));
#else
   setsockopt(_sipperInSocket, SOL_SOCKET, SO_REUSEADDR, 
              &flagOn, sizeof(flagOn));
#endif

   _inAddr = new sockaddr_in();
   memset(_inAddr, 0, sizeof(sockaddr_in));

   _inAddr->sin_family = AF_INET;
   _inAddr->sin_addr.s_addr = inet_addr(_inStrAddr.c_str());
   _inAddr->sin_port = htons(_inPort);

   if(bind(_sipperInSocket, (sockaddr *)_inAddr, sizeof(sockaddr_in)) < 0)
   {
      logger.logMsg(ERROR_FLAG, 0,
                    "Error binding port[%d]. [%s]\n", _inPort,
                    strerror(SipperProxyPortable::getErrorCode()));
      exit(1);
   }

   SipperProxyPortable::setNonBlocking(_sipperInSocket);

   if((_inStrAddr == _outStrAddr) && (_inPort == _outPort))
   {
      _outAddr = _inAddr;
      _sipperOutSocket = _sipperInSocket;
   }
   else
   {
      if((_sipperOutSocket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
      {
         logger.logMsg(ERROR_FLAG, 0, "Socket creation error. [%s]\n",
                       strerror(SipperProxyPortable::getErrorCode()));
         exit(1);
      }

      u_int flagOn = 1;
#ifndef __UNIX__
      setsockopt(_sipperOutSocket, SOL_SOCKET, SO_REUSEADDR, 
                 (const char *)&flagOn, sizeof(flagOn));
#else
      setsockopt(_sipperOutSocket, SOL_SOCKET, SO_REUSEADDR, 
                 &flagOn, sizeof(flagOn));
#endif

      _outAddr = new sockaddr_in();
      memset(_outAddr, 0, sizeof(sockaddr_in));

      _outAddr->sin_family = AF_INET;
      _outAddr->sin_addr.s_addr = inet_addr(_outStrAddr.c_str());
      _outAddr->sin_port = htons(_outPort);

      if(bind(_sipperOutSocket, (sockaddr *)_outAddr, sizeof(sockaddr_in)) < 0)
      {
         logger.logMsg(ERROR_FLAG, 0,
                       "Error binding port[%d]. [%s]\n", _outPort,
                       strerror(SipperProxyPortable::getErrorCode()));
         exit(1);
      }

      SipperProxyPortable::setNonBlocking(_sipperOutSocket);
   }

   _numOfSipperDomain = atoi(config.getConfig("Global", "NumSipperDomain", "0").c_str());

   if(_numOfSipperDomain == 0)
   {
      logger.logMsg(ERROR_FLAG, 0,
                    "Num of SipperDomain is invalid [%d].\n", _numOfSipperDomain);
      exit(1);
   }

   {
      std::string ipstr = config.getConfig("Global", "OutBoundProxyIp", "");

      outboundPxyIp = inet_addr(ipstr.c_str());

      std::string portinfo = config.getConfig("Global", "OutBouldProxyPort", "0");
      outboundPxyPort = atoi(portinfo.c_str());
   }

   sipperDomains = new SipperDomain[_numOfSipperDomain];

   for(unsigned int idx = 0; idx < _numOfSipperDomain; idx++)
   {
      char domainname[100];
      sprintf(domainname, "SipperDomain%d", idx + 1);

      std::string ipstr = config.getConfig(domainname, "Ip", "");

      if(ipstr == "")
      {
         logger.logMsg(ERROR_FLAG, 0,
                       "Empty IP for Domain[%s].\n", domainname);
         exit(1);
      }

      sipperDomains[idx].ip   = inet_addr(ipstr.c_str());

      if(sipperDomains[idx].ip == -1)
      {
         logger.logMsg(ERROR_FLAG, 0,
                       "Invalid IP[%s] for Domain[%s].\n", ipstr.c_str(), domainname);
         exit(1);
      }

      sipperDomains[idx].name = config.getConfig(domainname, "Name", ipstr);
      std::string portinfo = config.getConfig(domainname, "Port", "5060");
      sipperDomains[idx].port = atoi(portinfo.c_str());

      sipperDomains[idx].hostpart = sipperDomains[idx].name + ":" + portinfo;
      _dnsCache.addEntry(sipperDomains[idx].name, sipperDomains[idx].ip);
   }

   pxyStrIp = config.getConfig("ProxyDomain", "Ip", "");

   if(pxyStrIp == "")
   {
      logger.logMsg(ERROR_FLAG, 0, "Empty IP for ProxyDomain.\n");
      exit(1);
   }

   pxyStrDomain = config.getConfig("ProxyDomain", "Name", pxyStrIp);
   pxyStrPort = config.getConfig("ProxyDomain", "Port", "5060");

   pxyViaHdr = "Via: SIP/2.0/UDP " + _inStrAddr + ":" + _inStrPort + ";branch=";
   pxyRouteHdr = "Route: <sip:" + pxyStrDomain + ":" + pxyStrPort + ">\r\n";
   pxyRecordRouteHdr = "Record-Route: <sip:" + pxyStrDomain + ":" + pxyStrPort + ";lr>\r\n";
   pxyPathHdr = "Path: <sip:" + pxyStrDomain + ":" + pxyStrPort + ";lr>\r\n";
   pxyUriHost = pxyStrDomain + ":" + pxyStrPort;
   pxyUriIPHost = pxyStrIp + ":" + pxyStrPort;

   incPathHdr = (atoi(config.getConfig("Global", "IncludePathHeader", 
                                       "1").c_str()) == 0) ? false : true;
   incRecordRouteHdr = (atoi(config.getConfig("Global", 
                 "IncludeRecordRouteHeader", "1").c_str()) == 0) ? false : true;
   processMaxForward = (atoi(config.getConfig("Global", "ProcessMaxForwards",
                                        "1").c_str()) == 0) ? false : true;
   enableStatistics = (atoi(config.getConfig("Global", "EnableStatistics",
                                           "1").c_str()) == 0) ? false : true;

   if(enableStatistics)
   {
      _statMgr = SipperProxyStatMgr::getInstance();
   }
}

SipperProxy::~SipperProxy()
{
   if(_inAddr == _outAddr)
   {
      if(_inAddr != NULL) delete _inAddr;

      if(_sipperInSocket != -1) 
         SipperProxyPortable::disconnectSocket(_sipperInSocket);
   }
   else
   {
      if(_inAddr != NULL) delete _inAddr;
      if(_outAddr != NULL) delete _outAddr;

      if(_sipperInSocket != -1) 
         SipperProxyPortable::disconnectSocket(_sipperInSocket);
      if(_sipperOutSocket != -1) 
         SipperProxyPortable::disconnectSocket(_sipperOutSocket);
   }

   if(sipperDomains != NULL)
   {
      delete []sipperDomains;
   }
}

bool SipperProxy::isSipperDomain(in_addr_t addr, unsigned short port)
{
   for(int idx = 0; idx < _numOfSipperDomain; idx++)
   {
      if((sipperDomains[idx].ip == addr) && (sipperDomains[idx].port == port))
      {
         return true;
      }
   }

   return false;
}

void SipperProxy::setupStatistics(SipperProxyMsg *msg)
{
   if(!enableStatistics) return;

   struct timeval tv;
   SipperProxyPortable::getTimeOfDay(&tv);

   if(msg->msgToSipper)
   {
      int nameLen = strlen(msg->msgName);
      int branchLen = strlen(msg->incomingBranch);
      int callIdLen = strlen(msg->callId);
      int respReqLen = strlen(msg->respReq);

      SipperProxyRefObjHolder<SipperProxyRawMsg> holder(SipperProxyRawMsg::getFactoryMsg());
      SipperProxyRawMsg *rmsg = holder.getObj();
      rmsg->setLen(SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen + respReqLen);

      unsigned int bufLen;
      char *outBuf = rmsg->getBuf(bufLen);

      SET_INT_TO_BUF(bufLen, SMSG_RECLEN_OFF);
      outBuf[SMSG_DIREC_OFF] = 1;
      outBuf[SMSG_MSGTYPE_OFF] = msg->isRequest;
      outBuf[SMSG_NAME_LEN_OFF] = (char)nameLen;
      SET_SHORT_TO_BUF(branchLen, SMSG_BRN_LEN_OFF);
      SET_SHORT_TO_BUF(callIdLen, SMSG_CALL_LEN_OFF);
      SET_SHORT_TO_BUF(0, SMSG_MSG_LEN_OFF);
      SET_RAW_TO_BUF(&msg->recvSource.sin_addr, 4, SMSG_IP_OFF);
      SET_RAW_TO_BUF(&msg->recvSource.sin_port, 2, SMSG_PORT_OFF);
      SET_INT_TO_BUF(tv.tv_sec, SMSG_TIME_SEC_OFF);
      SET_INT_TO_BUF(tv.tv_usec, SMSG_TIME_USEC_OFF);
      outBuf[SMSG_RESP_REQ_LEN_OFF] = (char) respReqLen;
      SET_RAW_TO_BUF(msg->msgName, nameLen, SMSG_DYN_PART_OFF);
      SET_RAW_TO_BUF(msg->incomingBranch, branchLen, SMSG_DYN_PART_OFF + nameLen);
      SET_RAW_TO_BUF(msg->callId, callIdLen, SMSG_DYN_PART_OFF + nameLen + branchLen);
      SET_RAW_TO_BUF(msg->incomingMsg, 0, SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen);
      SET_RAW_TO_BUF(msg->respReq, respReqLen, SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen + 0);

      _statMgr->publish(rmsg);
   }

   if(msg->msgFromSipper)
   {
      int nameLen = strlen(msg->msgName);
      int branchLen = strlen(msg->outgoingBranch);
      int callIdLen = strlen(msg->callId);
      int respReqLen = strlen(msg->respReq);

      SipperProxyRefObjHolder<SipperProxyRawMsg> holder(SipperProxyRawMsg::getFactoryMsg());
      SipperProxyRawMsg *rmsg = holder.getObj();
      rmsg->setLen(SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen + respReqLen);

      unsigned int bufLen;
      char *outBuf = rmsg->getBuf(bufLen);

      SET_INT_TO_BUF(bufLen, SMSG_RECLEN_OFF);
      outBuf[SMSG_DIREC_OFF] = 0;
      outBuf[SMSG_MSGTYPE_OFF] = msg->isRequest;
      outBuf[SMSG_NAME_LEN_OFF] = (char)nameLen;
      SET_SHORT_TO_BUF(branchLen, SMSG_BRN_LEN_OFF);
      SET_SHORT_TO_BUF(callIdLen, SMSG_CALL_LEN_OFF);
      SET_SHORT_TO_BUF(0, SMSG_MSG_LEN_OFF);
      SET_RAW_TO_BUF(&msg->sendTarget.sin_addr, 4, SMSG_IP_OFF);
      SET_RAW_TO_BUF(&msg->sendTarget.sin_port, 2, SMSG_PORT_OFF);
      SET_INT_TO_BUF(tv.tv_sec, SMSG_TIME_SEC_OFF);
      SET_INT_TO_BUF(tv.tv_usec, SMSG_TIME_USEC_OFF);
      outBuf[SMSG_RESP_REQ_LEN_OFF] = (char) respReqLen;
      SET_RAW_TO_BUF(msg->msgName, nameLen, SMSG_DYN_PART_OFF);
      SET_RAW_TO_BUF(msg->outgoingBranch, branchLen, SMSG_DYN_PART_OFF + nameLen);
      SET_RAW_TO_BUF(msg->callId, callIdLen, SMSG_DYN_PART_OFF + nameLen + branchLen);
      SET_RAW_TO_BUF(msg->buffer, 0, SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen + callIdLen);
      SET_RAW_TO_BUF(msg->respReq, respReqLen, SMSG_DYN_PART_OFF + nameLen + branchLen + callIdLen + 0);

      _statMgr->publish(rmsg);
   }
}

void SipperProxy::start()
{
   fd_set read_fds;

   int maxSock = _sipperInSocket;

   if(_sipperOutSocket > maxSock) maxSock = _sipperOutSocket;

   SipperProxyMsg msg;

   while(true)
   {
      FD_ZERO(&read_fds);
      FD_SET(_sipperInSocket, &read_fds);
      FD_SET(_sipperOutSocket, &read_fds);

      struct timeval time_out;
      time_out.tv_sec = 5;
      time_out.tv_usec = 0;

      _dnsCache.checkCache();

      if(select(maxSock + 1, &read_fds, NULL, NULL, &time_out) == -1)
      {
         std::string errMsg = SipperProxyPortable::errorString();
         logger.logMsg(ERROR_FLAG, 0, "Error getting socket status. [%s]\n",
                       errMsg.c_str());
         continue;
      }

      memset(&msg.recvSource, 0, sizeof(sockaddr_in));
#ifdef __UNIX__
      socklen_t clilen = sizeof(sockaddr_in);
#else
      int clilen = sizeof(sockaddr_in);
#endif

      if(FD_ISSET(_sipperInSocket, &read_fds))
      {
         if((msg.bufferLen = recvfrom(_sipperInSocket, msg.buffer, 
                                      MAX_PROXY_MSG_LEN, 0, 
                                      (struct sockaddr *)&msg.recvSource, 
                                      &clilen)) <= 0)
         {
            continue;
         }

         msg.recvSocket = _sipperInSocket;
         msg.sendSocket = _sipperOutSocket;
      }
      else if(FD_ISSET(_sipperOutSocket, &read_fds))
      {
         if((msg.bufferLen = recvfrom(_sipperOutSocket, msg.buffer, 
                                      MAX_PROXY_MSG_LEN, 0, 
                                      (struct sockaddr *)&msg.recvSource, 
                                      &clilen)) <= 0)
         {
            continue;
         }

         msg.recvSocket = _sipperOutSocket;
         msg.sendSocket = _sipperInSocket;
      }
      else
      {
         continue;
      }

      msg.processMessage(this);
   }
}

SipperDomain * SipperProxy::getSipperDomain()
{
   SipperDomain *ret = sipperDomains + _toSendIndex;
   _toSendIndex ++;
   if(_toSendIndex >= _numOfSipperDomain) _toSendIndex = 0;

   return ret;
}

void SipperProxyMsg::processMessage(SipperProxy *context)
{
   _context = context;

   if(bufferLen < 0 || bufferLen > MAX_PROXY_MSG_LEN || bufferLen > 30000)
   {
      logger.logMsg(ERROR_FLAG, 0, "Invalid MessageLen [%d]\n", bufferLen);
      return;
   }

   respReq[0] = '\0';
   buffer[bufferLen] = '\0';
   if(_context->enableStatistics)
   {
      memcpy(incomingMsg, buffer, bufferLen + 1);
      incomingMsgLen = bufferLen;
   }

   msgFromSipper = false;
   msgToSipper = false;

   unsigned short incomingPort = ntohs(recvSource.sin_port);
   msgFromSipper = _context->isSipperDomain(recvSource.sin_addr.s_addr, 
                                            incomingPort);

   logger.logMsg(TRACE_FLAG, 0, "ReceivedMessage From[%s:%d]\n---\n[%s]\n---",
                 inet_ntoa(recvSource.sin_addr), ntohs(recvSource.sin_port),
                 buffer);

   if(strncmp(buffer, "SIP/2.0", 7) == 0)
   {
      isRequest = false;

      if(_context->enableStatistics)
      {
         char *nameStart = buffer + 7;
         while(*nameStart == ' ') nameStart++;

         int cnt = 0;
         char *maxEnd = buffer + bufferLen;
         while(*nameStart != ' ' && cnt != 50 &&
               nameStart < maxEnd)
         {
            msgName[cnt] = *nameStart;
            nameStart++;
            cnt++;
         }
         msgName[cnt] = '\0';
      }

      char *end = strstr(buffer, "\r\n");
      if(end == NULL)
      {
         logger.logMsg(ERROR_FLAG, 0, "Invalid Message [%s]\n", buffer);
         return;
      }

      hdrStart = end + 2;

      if(_context->enableStatistics)
      {
         _getCallId();
         _getCSeqMethod();
      }
      _processResponse();
   }
   else
   {
      isRequest = true;

      if(_context->enableStatistics)
      {
         char *nameStart = buffer;
         while(*nameStart == ' ') nameStart++;

         int cnt = 0;
         char *maxEnd = buffer + bufferLen;
         while(*nameStart != ' ' && cnt != 50 &&
               nameStart < maxEnd)
         {
            msgName[cnt] = *nameStart;
            nameStart++;
            cnt++;
         }

         msgName[cnt] = '\0';
      }

      char *end = strstr(buffer, "\r\n");
      if(end == NULL)
      {
         logger.logMsg(ERROR_FLAG, 0, "Invalid Message [%s]\n", buffer);
         return;
      }
      
      end -= 7;

      if((end > buffer) && (strncmp(end, "SIP/2.0", 7) == 0))
      {
         hdrStart = end + 9;
         if(_context->enableStatistics)
         {
            _getCallId();
         }
         _processRequest();
      }
      else
      {
         logger.logMsg(ERROR_FLAG, 0, "Invalid Message [%s]\n", buffer);
         return;
      }
   }
}

void SipperProxyMsg::_processResponse()
{
   if(_removeFirstVia() == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Failed to remove VIA [%s]\n", buffer);
      return;
   }

   if(_setTargetFromFirstVia() == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Error getting Targer from VIA [%s]\n", 
                    buffer);
      return;
   }

   logger.logMsg(TRACE_FLAG, 0, "SendingResponse To[%s:%d] Len[%d]\n---\n[%s]\n---",
                 inet_ntoa(sendTarget.sin_addr), ntohs(sendTarget.sin_port),
                 bufferLen, buffer);

   sendto(sendSocket, buffer, bufferLen, 0, (struct sockaddr *)&sendTarget,
          sizeof(sockaddr_in));

   msgToSipper = _context->isSipperDomain(sendTarget.sin_addr.s_addr, 
                                          ntohs(sendTarget.sin_port));
   if(_context->enableStatistics)
   {
      _context->setupStatistics(this);
   }
}

int SipperProxyMsg::_getCallId()
{
   char *callIdStart = NULL;
   char *callIdValStart = NULL;

   callId[0] = '\0';
   char *fullForm = strstr(hdrStart - 2, "\r\nCall-ID:");
   char *shortForm = NULL;

   if(fullForm != NULL)
   {
      char locTmp = *fullForm;
      *fullForm = '\0';
      shortForm = strstr(hdrStart - 2, "\r\ni:");
      *fullForm = locTmp;
   }
   else
   {
      shortForm = strstr(hdrStart - 2, "\r\ni:");
   }

   char *callIdToUse = fullForm;

   if(callIdToUse == NULL) 
   {
      callIdToUse = shortForm;
   }
   else 
   {
      if((shortForm != NULL) && (shortForm < fullForm))
      {
         callIdToUse = shortForm;
      }
   }

   if(callIdToUse == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No CallId found. \n");
      return -1;
   }

   if(callIdToUse == fullForm) 
   {
      callIdStart = fullForm + 2;
      callIdValStart = fullForm + 10;
   }
   else
   {
      callIdStart = shortForm + 2;
      callIdValStart = shortForm + 4;
   }

   while(*callIdValStart == ' ') callIdValStart++;

   char *src = callIdValStart;
   char *tgt = callId;
   int tgtlen = 0;
   while(*src != '\r' && *src != '\n' &&
         *src != ' ' && *src != '\0' && tgtlen < 250)
   {
      *tgt = *src;
      tgtlen++;
      tgt++;
      src++;
   }

   *tgt = '\0';
   return 0;
}

int SipperProxyMsg::_getCSeqMethod()
{
   char *cseqStart = NULL;
   char *cseqMethodStart = NULL;

   respReq[0] = '\0';
   char *cseqToUse = strstr(hdrStart - 2, "\r\nCseq:");

   if(cseqToUse == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Cseq found.\n");
      return -1;
   }

   cseqStart = cseqToUse + 2;
   cseqMethodStart = cseqToUse + 7;

   while(*cseqMethodStart == ' ') cseqMethodStart++;
   char *src = cseqMethodStart;
   while(*src != '\r' && *src != '\n' &&
         *src != ' ' && *src != '\0') src++;
   cseqMethodStart = src;
   while(*cseqMethodStart == ' ') cseqMethodStart++;

   src = cseqMethodStart;
   char *tgt = respReq;
   int tgtlen = 0;
   while(*src != '\r' && *src != '\n' &&
         *src != ' ' && *src != '\0' && tgtlen < 50)
   {
      *tgt = *src;
      tgtlen++;
      tgt++;
      src++;
   }

   *tgt = '\0';
   return 0;
}

int SipperProxyMsg::_getFirstVia(char *&viaStart, char *&viaValStart)
{
   char *fullForm = strstr(hdrStart - 2, "\r\nVia:");
   char *shortForm = NULL;

   if(fullForm != NULL)
   {
      char locTmp = *fullForm;
      *fullForm = '\0';
      shortForm = strstr(hdrStart - 2, "\r\nv:");
      *fullForm = locTmp;
   }
   else
   {
      shortForm = strstr(hdrStart - 2, "\r\nv:");
   }

   char *viaToUse = fullForm;

   if(viaToUse == NULL) 
   {
      viaToUse = shortForm;
   }
   else 
   {
      if((shortForm != NULL) && (shortForm < fullForm))
      {
         viaToUse = shortForm;
      }
   }

   if(viaToUse == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Via found. \n");
      return -1;
   }

   if(viaToUse == fullForm) 
   {
      viaStart = fullForm + 2;
      viaValStart = fullForm + 6;
   }
   else
   {
      viaStart = shortForm + 2;
      viaValStart = shortForm + 4;
   }

   while(*viaValStart == ' ') viaValStart++;

   return 0;
}

void SipperProxyMsg::_removeData(char *from, char *to)
{
   if(to < from) return;

   memmove(from, to, (buffer + bufferLen) - to + 1);
   bufferLen -= (to - from);
}

void SipperProxyMsg::_addToBuffer(char *startPos, const char *insData, int len)
{
   memmove(startPos + len, startPos, bufferLen - (startPos - buffer) + 1);
   memcpy(startPos, insData, len);
   bufferLen += len;
}

void SipperProxyMsg::_replaceData(char *from, char *to, const char *insData, int len)
{
   if(len == (to - from))
   {
      memcpy(from, insData, len);
   }
   else if(len < (to - from))
   {
      memcpy(from, insData, len);
      _removeData(from + len, to);
   }
   else 
   {
     memcpy(from, insData, (to - from));
     _addToBuffer(to, insData + (to - from), len - (to - from));
   }
}

int SipperProxyMsg::_removeFirstVia()
{
   char *viaStart = NULL;
   char *viaValStart = NULL;

   if(_getFirstVia(viaStart, viaValStart) == -1)
   {
      return -1;
   }

   char *viaEnd = strstr(viaValStart, "\r\n");

   if(viaEnd == NULL) 
   {
      logger.logMsg(ERROR_FLAG, 0, "No Via End found.\n");
      return -1;
   }

   char tmpData = *viaEnd;
   *viaEnd = '\0';
   char *viaValEnd = strstr(viaValStart, ",");
   *viaEnd = tmpData;

   if(_context->enableStatistics)
   {
      char *viaAnaStart = strstr(viaValStart, ";branch=");
      if(viaAnaStart != NULL && viaAnaStart < viaEnd)
      {
         viaAnaStart += 8;
         char *branchTarget = incomingBranch;
         int cnt = 0;
         while(*viaAnaStart != ';' && *viaAnaStart != '\0' &&
               *viaAnaStart != ',' && *viaAnaStart != '\r' && cnt < 250)
         {
            *branchTarget = *viaAnaStart;
            branchTarget++;
            viaAnaStart++;
            cnt++;
         }
   
         *branchTarget = '\0';
      }
   }

   if((viaValEnd == NULL) || (viaEnd < viaValEnd))
   {
      //RemoveFullHeader
      _removeData(viaStart, viaEnd + 2);
   }
   else
   {
      //Comma separated value. Remove till ,.
      _removeData(viaValStart, viaValEnd + 1);
   }
}

int SipperProxyMsg::_setTargetFromFirstVia()
{
   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;

   char *viaStart = NULL;
   char *viaValStart = NULL;

   if(_getFirstVia(viaStart, viaValStart) == -1)
   {
      return -1;
   }

   while(*viaValStart == ' ') viaValStart++;

   while(*viaValStart != ' ' && *viaValStart != '\0' &&
         *viaValStart != ',' && *viaValStart != '\r') viaValStart++;

   if(*viaValStart != ' ') return -1;

   while(*viaValStart == ' ') viaValStart++;

   char *hostStart = viaValStart;
   char *portStart = viaValStart;

   while(*portStart != ':' && *portStart != '\r' && *portStart != ',' && *portStart != '\0' && *portStart != ';')
   {
      portStart++;
   }

   std::string hostname(hostStart, portStart - hostStart);
   unsigned short port = 5060;

   if(*portStart == ':')
   {
      portStart++;
      port = atoi(portStart);

      while(*portStart != ':' && *portStart != '\r' && 
            *portStart != ',' && *portStart != '\0' && *portStart != ';')
      {
         portStart++;
      }
   }

   char *paramStart = portStart;

   while(*paramStart == ';')
   {
      paramStart++;
      while(*paramStart == ' ') paramStart++;

      if(strncmp(paramStart, "rport=", 6) == 0)
      {
         paramStart += 6;
         port = atoi(paramStart);
      }
      else if(strncmp(paramStart, "received=", 9) == 0)
      {
         paramStart += 9;
         hostStart = paramStart;
         char *hostend = paramStart;

         while(*hostend != ';' && *hostend != '\0' &&
               *hostend != ',' && *hostend != '\r') hostend++;

         hostname.assign(hostStart, hostend - hostStart);
         paramStart = hostend;
      }
      else if(strncmp(paramStart, "branch=", 7) == 0)
      {
         paramStart += 7;
         char *branchTarget = outgoingBranch;
         int cnt = 0;
         while(*paramStart != ';' && *paramStart != '\0' &&
               *paramStart != ',' && *paramStart != '\r' && cnt < 250)
         {
            *branchTarget = *paramStart;
            branchTarget++;
            paramStart++;
            cnt++;
         }

         *branchTarget = '\0';
      }

      while(*paramStart != ';' && *paramStart != '\0' &&
            *paramStart != ',' && *paramStart != '\r') paramStart++;
   }

   sendTarget.sin_port = htons(port);
   sendTarget.sin_addr.s_addr = _context->getIp(hostname);

   if(sendTarget.sin_addr.s_addr == -1)
   {
      return -1;
   }

   return 0;
}

void SipperProxyMsg::_processRequest()
{
   if(_processMaxForward() == -1)
   {
      return;
   }

   if(_processViaRport() == -1)
   {
      return;
   }

   _addViaHeader();

   if(_isRegisterRequest())
   {
      _addPathHeader();
   }
   else
   {
      _addRecordRouteHeader();
   }

   if(_isRoutePresent())
   {
      bool lrFlag = false;
      if(_isReqURIContainsProxyDomain(lrFlag))
      {
         if(lrFlag)
         {
            //Message from StrictRouter.
            _moveLastRouteToReqURI();
         }
         else
         {
            _removeFirstRouteIfProxyDomain();
         }
      }
      else
      {
         _removeFirstRouteIfProxyDomain();
      }

      if(_isRoutePresent())
      {
         lrFlag = false;
         if(_setTargetFromFirstRoute(lrFlag) == -1)
         {
            _setTargetFromReqURI();
         }
         else
         {
            if(!lrFlag) 
            {
               logger.logMsg(ERROR_FLAG, 0, "NextHop is strictRouter..\n");
               _moveFirstRouteToReqURIAndReqURIToLastRoute();
            }
         }
      }
      else
      {
         if(msgFromSipper && (_context->outboundPxyPort != 0))
         {
            _setTargetFromOutboundPxy();
         }
         else
         {
            _setTargetFromReqURI();
         }
      }
   }
   else
   {
      if(msgFromSipper && (_context->outboundPxyPort != 0))
      {
         _setTargetFromOutboundPxy();
      }
      else
      {
         bool lrFlag = false;
         if(_isReqURIContainsProxyDomain(lrFlag))
         {
            //Choose one from the SipperDomain
            _setTargetFromSipperDomain();
         }
         else
         {
            _setTargetFromReqURI();
         }
      }
   }

   logger.logMsg(TRACE_FLAG, 0, "SendingRequest To[%s:%d] Len[%d]\n---\n[%s]\n---",
                 inet_ntoa(sendTarget.sin_addr), ntohs(sendTarget.sin_port),
                 bufferLen, buffer);

   sendto(sendSocket, buffer, bufferLen, 0, (struct sockaddr *)&sendTarget,
          sizeof(sockaddr_in));
   if(_context->enableStatistics)
   {
      msgToSipper = _context->isSipperDomain(sendTarget.sin_addr.s_addr, 
                                             ntohs(sendTarget.sin_port));
      _context->setupStatistics(this);
   }
}

int SipperProxyMsg::_processViaRport()
{
   incomingBranch[0] = '\0';
   char *viaStart = NULL;
   char *viaValStart = NULL;

   if(_getFirstVia(viaStart, viaValStart) == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "No via found in the request received.\n");
      return -1;
   }

   while(*viaValStart != ';' && *viaValStart != '\0' &&
         *viaValStart != ',' && *viaValStart != '\r') viaValStart++;

   char insData[100];
   int insLen= sprintf(insData, ";received=%s", inet_ntoa(recvSource.sin_addr));

   _addToBuffer(viaValStart, insData, insLen);

   while(*viaValStart == ';')
   {
      if(strncmp(viaValStart, ";rport", 6) == 0)
      {
         viaValStart += 6;
         insLen = sprintf(insData, "=%d", ntohs(recvSource.sin_port));
         _addToBuffer(viaValStart, insData, insLen);
      }
      else if(strncmp(viaValStart, ";branch=", 8) == 0)
      {
         viaValStart += 8;
         char *branchTarget = incomingBranch;
         int cnt = 0;
         while(*viaValStart != ';' && *viaValStart != '\0' &&
               *viaValStart != ',' && *viaValStart != '\r' && cnt < 250)
         {
            *branchTarget = *viaValStart;
            branchTarget++;
            viaValStart++;
            cnt++;
         }

         *branchTarget = '\0';
      }
      else
      {   viaValStart++;
      }

      while(*viaValStart != ';' && *viaValStart != '\0' &&
            *viaValStart != ',' && *viaValStart != '\r') viaValStart++;
   }

   return 0;
}

void SipperProxyMsg::_addViaHeader()
{
   char viaHeader[1000];
   int viaLen = 0;
   if(*incomingBranch == '\0')
   {
      struct timeval tv;
      gettimeofday(&tv, NULL);

      sprintf(outgoingBranch, "z9hG4bK_%d_%d_%d", tv.tv_sec, tv.tv_usec, rand());
      viaLen = sprintf(viaHeader, "%s%s\r\n", _context->pxyViaHdr.c_str(), 
                       outgoingBranch);
   }
   else
   {
      sprintf(outgoingBranch, "%s_0", incomingBranch);
      viaLen = sprintf(viaHeader, "%s%s\r\n", _context->pxyViaHdr.c_str(), outgoingBranch);
   }

   _addToBuffer(hdrStart, viaHeader, viaLen);
}

int SipperProxyMsg::_processMaxForward()
{
   if(!_context->processMaxForward)
   {
      return 0;
   }

   char *maxFwdStart = strstr(hdrStart - 2, "\r\nMax-Forwards:");

   if(maxFwdStart == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "Max-Forwards not found in message.\n");
      return 0;
   }

   maxFwdStart += 15;

   while(*maxFwdStart == ' ') maxFwdStart++;

   int currmaxFwd = atoi(maxFwdStart);

   if(currmaxFwd <= 0)
   {
      logger.logMsg(ERROR_FLAG, 0, "Max-Forwards limit reached.\n");
      return -1;
   }

   currmaxFwd--;

   char *maxFwdEnd = maxFwdStart;
   if(*maxFwdEnd == '-') maxFwdEnd++;

   while(isdigit(*maxFwdEnd)) maxFwdEnd++;

   char tmpdata[30];
   int tmplen = sprintf(tmpdata, "%d", currmaxFwd);

   _replaceData(maxFwdStart, maxFwdEnd, tmpdata, tmplen);
   return 0;
}

void SipperProxyMsg::_addPathHeader()
{
   if(_context->incPathHdr)
   {
      _addToBuffer(hdrStart, _context->pxyPathHdr.c_str(), 
                   _context->pxyPathHdr.length());
   }
}

void SipperProxyMsg::_addRecordRouteHeader()
{
   if(_context->incRecordRouteHdr)
   {
      _addToBuffer(hdrStart, _context->pxyRecordRouteHdr.c_str(), 
                   _context->pxyRecordRouteHdr.length());
   }
}

bool SipperProxyMsg::_isRegisterRequest()
{
   if(strncmp(buffer, "REGISTER ", 9) == 0)
   {
      return true;
   }

   return false;
}

bool SipperProxyMsg::_isRoutePresent()
{
   _routeStart = strstr(hdrStart - 2, "\r\nRoute:");
   if(_routeStart != NULL)
   {
      _routeStart += 2;
      return true;
   }

   return false;
}

bool SipperProxyMsg::_isReqURIContainsProxyDomain(bool &lrFlag)
{
   lrFlag = false;

   char tmp = *hdrStart;
   *hdrStart = '\0';

   if(strstr(buffer, ";lr") != NULL)
   {
      lrFlag = true;
   }

   if((strstr(buffer, _context->pxyUriHost.c_str()) != NULL) ||
      (strstr(buffer, _context->pxyUriIPHost.c_str()) != NULL))
   {
      *hdrStart = tmp;
      return true;
   }


   if(_context->pxyStrPort == "5060")
   {
      int len = _context->pxyStrDomain.length();
      char *domainstart = strstr(buffer, _context->pxyStrDomain.c_str());

      if(domainstart != NULL)
      {
         if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
            (*(domainstart + len) == ' ' || *(domainstart + len) == '>' || 
             *(domainstart + len) == ';'))
         {
            *hdrStart = tmp;
            return true;
         }
      }

      len = _context->pxyStrIp.length();
      domainstart = strstr(buffer, _context->pxyStrIp.c_str());

      if(domainstart != NULL)
      {
         if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
            (*(domainstart + len) == ' ' || *(domainstart + len) == '>' || 
             *(domainstart + len) == ';'))
         {
            *hdrStart = tmp;
            return true;
         }
      }
   }

   *hdrStart = tmp;
   return false;
}

int SipperProxyMsg::_getFirstRoute(char *&routeStart, char *&routeValStart)
{
   char *routeToUse = strstr(hdrStart - 2, "\r\nRoute:");

   if(routeToUse == NULL)
   {
      logger.logMsg(TRACE_FLAG, 0, "No Route found. \n");
      return -1;
   }

   routeStart = routeToUse + 2;
   routeValStart = routeToUse + 8;

   while(*routeValStart == ' ') routeValStart++;

   return 0;
}

int SipperProxyMsg::_getFirstRoute(char *&routeStart, char *&routeEnd, bool &singleHdr,
                                  char *&routeValStart, char *&routeValEnd)
{
   char *routeToUse = strstr(hdrStart - 2, "\r\nRoute:");

   if(routeToUse == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Route found. \n");
      return -1;
   }

   routeStart = routeToUse + 2;
   routeValStart = routeToUse + 8;

   routeEnd = strstr(routeValStart, "\r\n");

   if(routeEnd == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Route End found. \n");
      return -1;
   }

   routeValEnd = routeEnd;
   routeEnd += 2;

   singleHdr = true;

   char tmpData = *routeEnd;
   *routeEnd = '\0';
   char *firstComma = index(routeValStart, ',');
   *routeEnd = tmpData;

   if(firstComma != NULL)
   {
      singleHdr = false;
      routeValEnd = firstComma - 1;
      routeEnd = firstComma;
   }

   return 0;
}

int SipperProxyMsg::_getLastRoute(char *&routeStart, char *&routeEnd, bool &singleHdr,
                                  char *&routeValStart, char *&routeValEnd)
{
   char *routeToUse = strstr(hdrStart - 2, "\r\nRoute:");

   while(routeToUse != NULL)
   {
      char *tmpPtr = strstr(routeToUse + 8, "\r\nRoute:");

      if(tmpPtr != NULL) routeToUse = tmpPtr;
      else
        break;
   }

   if(routeToUse == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Route found. \n");
      return -1;
   }

   routeStart = routeToUse + 2;
   routeValStart = routeToUse + 8;

   routeEnd = strstr(routeValStart, "\r\n");

   if(routeEnd == NULL)
   {
      logger.logMsg(ERROR_FLAG, 0, "No Route End found. \n");
      return -1;
   }

   routeValEnd = routeEnd;
   routeEnd += 2;

   singleHdr = true;

   char tmpData = *routeEnd;
   *routeEnd = '\0';
   char *lastComma = rindex(routeValStart, ',');
   *routeEnd = tmpData;

   if(lastComma != NULL)
   {
      singleHdr = false;
      routeValStart = lastComma + 1;
      routeValEnd = routeEnd - 2;
   }

   return 0;
}

void SipperProxyMsg::_removeFirstRouteIfProxyDomain()
{
   char *routeStart = NULL;
   char *routeValStart = NULL;
   if(_getFirstRoute(routeStart, routeValStart) == -1)
   {
      return;
   }

   char *routeEnd = strstr(routeValStart, "\r\n");

   if(routeEnd == NULL)
   {
      return;
   }

   char tmpData = *routeEnd;
   *routeEnd = '\0';
   char *routeValEnd = strstr(routeValStart, ",");
   *routeEnd = tmpData;

   if((routeValEnd == NULL) || (routeEnd < routeValEnd))
   {
      routeValEnd = routeEnd;

      tmpData = *routeValEnd;
      *routeValEnd = '\0';
      char *lrparam = strstr(routeValStart, ";lr");
      *routeValEnd = tmpData;

      if(lrparam == NULL)
      {
         logger.logMsg(TRACE_FLAG, 0, 
                       "lrParam not found in the FirstRoute.\n");
         return;
      }

      tmpData = *routeValEnd;
      *routeValEnd = '\0';
      if((strstr(routeValStart, _context->pxyUriHost.c_str()) != NULL) ||
         (strstr(routeValStart, _context->pxyUriIPHost.c_str()) != NULL))
      {
         *routeValEnd = tmpData;;
         _removeData(routeStart, routeEnd + 2);
         return;
      }

      if(_context->pxyStrPort == "5060")
      {
         int len = _context->pxyStrDomain.length();
         char *domainstart = strstr(routeValStart, _context->pxyStrDomain.c_str());
   
         if(domainstart != NULL)
         {
            if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
               (*(domainstart + len) == ',' || *(domainstart + len) == '>' || 
                *(domainstart + len) == ';'))
            {
               *routeValEnd = tmpData;
               _removeData(routeStart, routeEnd + 2);
               return;
            }
         }

         len = _context->pxyStrIp.length();
         domainstart = strstr(routeValStart, _context->pxyStrIp.c_str());
   
         if(domainstart != NULL)
         {
            if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
               (*(domainstart + len) == ',' || *(domainstart + len) == '>' || 
                *(domainstart + len) == ';'))
            {
               *routeValEnd = tmpData;
               _removeData(routeStart, routeEnd + 2);
               return;
            }
         }
      }

      *routeValEnd = tmpData;;
      return;
   }

   tmpData = *routeValEnd;
   *routeValEnd = '\0';
   char *lrparam = strstr(routeValStart, ";lr");
   *routeValEnd = tmpData;

   if(lrparam == NULL)
   {
      logger.logMsg(TRACE_FLAG, 0, 
                    "lrParam not found in the FirstRoute.\n");
      return;
   }

   tmpData = *routeValEnd;
   *routeValEnd = '\0';
   if((strstr(routeValStart, _context->pxyUriHost.c_str()) != NULL) ||
      (strstr(routeValStart, _context->pxyUriIPHost.c_str()) != NULL))
   {
      *routeValEnd = tmpData;;
      _removeData(routeValStart, routeValEnd + 1);
      return;
   }

   if(_context->pxyStrPort == "5060")
   {
      int len = _context->pxyStrDomain.length();
      char *domainstart = strstr(routeValStart, _context->pxyStrDomain.c_str());
  
      if(domainstart != NULL)
      {
         if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
            (*(domainstart + len) == ',' || *(domainstart + len) == '>' || 
             *(domainstart + len) == ';'))
         {
            *routeValEnd = tmpData;
            _removeData(routeValStart, routeValEnd + 1);
            return;
         }
      }

      len = _context->pxyStrIp.length();
      domainstart = strstr(routeValStart, _context->pxyStrIp.c_str());
  
      if(domainstart != NULL)
      {
         if((*(domainstart - 1) == '@' || *(domainstart - 1) == ':') &&
            (*(domainstart + len) == ',' || *(domainstart + len) == '>' || 
             *(domainstart + len) == ';'))
         {
            *routeValEnd = tmpData;
            _removeData(routeValStart, routeValEnd + 1);
            return;
         }
      }
   }

   *routeValEnd = tmpData;;
   return;
}

void SipperProxyMsg::_moveFirstRouteToReqURIAndReqURIToLastRoute()
{
   char *routeStart = NULL;
   char *routeEnd = NULL;
   char *routeValStart = NULL;
   char *routeValEnd = NULL;
   bool singleHdr = false;

   if(_getFirstRoute(routeStart, routeEnd, singleHdr, routeValStart, routeValEnd) == -1)
   {
      return;
   }

   char routeHdr[1000];
   if(singleHdr)
   {
      strncpy(routeHdr, routeValStart, (routeValEnd - routeValStart));
      _removeData(routeStart, routeEnd);
   }
   else
   {
      strncpy(routeHdr, routeValStart, (routeValEnd - routeValStart));
      _removeData(routeValStart, routeEnd + 1);
   }

   char *storedHdr = routeHdr;
   while(*storedHdr == ' ' || *storedHdr == '<') storedHdr++;

   char *storedRouteStart = storedHdr;
   while(*storedHdr != ' ' && *storedHdr != '>' && *storedHdr != '\0') storedHdr++;
   *storedHdr = '\0';

   char tmpData = *hdrStart;
   *hdrStart = '\0';
   char *requriStart = strstr(buffer, " ");
   while(*requriStart == ' ') requriStart++;
   *hdrStart = tmpData;

   if(requriStart == NULL)
   {
      logger.logMsg(TRACE_FLAG, 0, "Invalid ReqURI.\n");
      return;
   }

   char newRoute[1000];
   strcpy(newRoute, "Route: <");

   if(hdrStart - 10 > requriStart + 1)
   {
      char *requriend = hdrStart - 10;
      tmpData = *requriend;
      *requriend = '\0';
      strcpy(newRoute + 8, requriStart);
      *requriend = tmpData;
      strcat(newRoute + 8 + (requriend - requriStart), ">\r\n");

      _replaceData(requriStart, hdrStart - 10, 
                   storedRouteStart, strlen(storedRouteStart));

      if(_getLastRoute(routeStart, routeEnd, singleHdr,
                       routeValStart, routeValEnd) == -1)
      {
         return;
      }

      if(singleHdr)
      {
         _addToBuffer(routeEnd, newRoute, strlen(newRoute));
      }
      else
      {
         _addToBuffer(routeEnd + 2, newRoute, strlen(newRoute));
      }
   }

   char *end = strstr(buffer, "\r\n");
   hdrStart = end + 2;
}

void SipperProxyMsg::_moveLastRouteToReqURI()
{
   char *routeStart = NULL;
   char *routeEnd = NULL;
   char *routeValStart = NULL;
   char *routeValEnd = NULL;
   bool singleHdr = false;

   if(_getLastRoute(routeStart, routeEnd, singleHdr,
                    routeValStart, routeValEnd) == -1)
   {
      return;
   }

   char routeHdr[1000];
   if(singleHdr)
   {
      strncpy(routeHdr, routeValStart, (routeValEnd - routeValStart));
      _removeData(routeStart, routeEnd);
   }
   else
   {
      strncpy(routeHdr, routeValStart, (routeValEnd - routeValStart));
      _removeData(routeValStart -1, routeValEnd);
   }

   char *storedHdr = routeHdr;
   while(*storedHdr == ' ' || *storedHdr == '<') storedHdr++;

   char *storedRouteStart = storedHdr;
   while(*storedHdr != ' ' && *storedHdr != '>' && *storedHdr != '\0') storedHdr++;
   *storedHdr = '\0';

   char tmpData = *hdrStart;
   *hdrStart = '\0';
   char *requriStart = strstr(buffer, " ");
   *hdrStart = tmpData;

   if(requriStart == NULL)
   {
      logger.logMsg(TRACE_FLAG, 0, "Invalid ReqURI.\n");
      return;
   }

   if(hdrStart - 10 > requriStart + 1)
   {
      _replaceData(requriStart + 1, hdrStart - 10, 
                   storedRouteStart, strlen(storedRouteStart));
   }

   char *end = strstr(buffer, "\r\n");
   hdrStart = end + 2;
}

int SipperProxyMsg::_setTargetFromFirstRoute(bool &lrFlag)
{
   lrFlag = false;
   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;

   char *routeStart = NULL;
   char *routeValStart = NULL;

   if(_getFirstRoute(routeStart, routeValStart) == -1)
   {
      return -1;
   }

   while(*routeValStart == ' ') routeValStart++;

   while(*routeValStart != ':' && *routeValStart != '\0' &&
         *routeValStart != ';' && *routeValStart != '>' &&
         *routeValStart != ',' && *routeValStart != '\r') routeValStart++;

   if(*routeValStart != ':') return -1;

   routeValStart++;
   char *hostStart = routeValStart;

   while(*routeValStart != ':' && *routeValStart != '\0' &&
         *routeValStart != ';' && *routeValStart != '>' && *routeValStart != '@' &&
         *routeValStart != ',' && *routeValStart != '\r') routeValStart++;

   if(*routeValStart == '@') 
   {
      routeValStart++;
      hostStart = routeValStart;
   }
   
   while(*routeValStart != ':' && *routeValStart != '\0' &&
         *routeValStart != ';' && *routeValStart != '>' && 
         *routeValStart != ',' && *routeValStart != '\r') routeValStart++;

   unsigned short port = 5060;

   if(*routeValStart == ':')
   {
      port = atoi(routeValStart + 1);
   }

   std::string hostname(hostStart, routeValStart - hostStart);

   if(*routeValStart == ':')
   {
      while(*routeValStart != '\0' &&
            *routeValStart != ';' && *routeValStart != '>' && 
            *routeValStart != ',' && *routeValStart != '\r') routeValStart++;
   }

   while(*routeValStart == ';')
   {
      if(strncmp(routeValStart, ";lr", 3) == 0)
      {
         lrFlag = true;
         break;
      }

      routeValStart++;
      while(*routeValStart != '\0' &&
            *routeValStart != ';' && *routeValStart != '>' && 
            *routeValStart != ',' && *routeValStart != '\r') routeValStart++;
   }

   sendTarget.sin_port = htons(port);
   sendTarget.sin_addr.s_addr = _context->getIp(hostname);

   if(sendTarget.sin_addr.s_addr == -1)
   {
      return -1;
   }

   return 0;
}

int SipperProxyMsg::_setTargetFromSipperDomain()
{
   SipperDomain *domain = _context->getSipperDomain();

   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;
   sendTarget.sin_port = htons(domain->port);
   sendTarget.sin_addr.s_addr = domain->ip;

   char *uriStart = buffer;

   while(*uriStart != ' ' && *uriStart != '\0' &&
         *uriStart != '\r') uriStart++;

   if(*uriStart != ' ') return -1;

   while(*uriStart == ' ') uriStart++;

   while(*uriStart != ':' && *uriStart != '\0' &&
         *uriStart != '\r') uriStart++;

   if(*uriStart != ':') return -1;

   uriStart++;

   char *hostStart = uriStart;
   while(*uriStart != '@' && *uriStart != '\0' && *uriStart != ':' &&
         *uriStart != ';' && *uriStart != '>' && *uriStart != ' ' &&
         *uriStart != ',' && *uriStart != '\r') uriStart++;

   if(*uriStart == '@')
   {
      uriStart++;
      hostStart = uriStart;
   }

   while(*uriStart != '\0' &&
         *uriStart != ';' && *uriStart != '>' && *uriStart != ' ' &&
         *uriStart != ',' && *uriStart != '\r') uriStart++;

   char *hostEnd = uriStart;
   //_removeData(hostStart, hostEnd);
   //_addToBuffer(hostStart, domain->hostpart.c_str(), domain->hostpart.length());
   _replaceData(hostStart, hostEnd, domain->hostpart.c_str(), domain->hostpart.length());

   char *end = strstr(buffer, "\r\n");
   hdrStart = end + 2;

   return 0;
}

int SipperProxyMsg::_setTargetFromOutboundPxy()
{
   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;
   sendTarget.sin_port = htons(_context->outboundPxyPort);
   sendTarget.sin_addr.s_addr = _context->outboundPxyIp;

   if(sendTarget.sin_addr.s_addr == -1)
   {
      return -1;
   }

   return 0;
}

int SipperProxyMsg::_setTargetFromReqURI()
{
   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;

   char *uriStart = buffer;

   while(*uriStart != ' ' && *uriStart != '\0' &&
         *uriStart != '\r') uriStart++;

   if(*uriStart != ' ') return -1;

   while(*uriStart == ' ') uriStart++;

   while(*uriStart != ':' && *uriStart != '\0' &&
         *uriStart != '\r') uriStart++;

   if(*uriStart != ':') return -1;

   uriStart++;

   char *hostStart = uriStart;
   while(*uriStart != '@' && *uriStart != '\0' && *uriStart != ':' &&
         *uriStart != ';' && *uriStart != '>' && *uriStart != ' ' &&
         *uriStart != ',' && *uriStart != '\r') uriStart++;

   if(*uriStart == '@')
   {
      uriStart++;
      hostStart = uriStart;
   }

   while(*uriStart != ':' && *uriStart != '\0' &&
         *uriStart != ';' && *uriStart != '>' && *uriStart != ' ' &&
         *uriStart != ',' && *uriStart != '\r') uriStart++;

   unsigned short port = 5060;

   if(*uriStart == ':')
   {
      port = atoi(uriStart + 1);
   }

   std::string hostname(hostStart, uriStart - hostStart);

   sendTarget.sin_port = htons(port);
   sendTarget.sin_addr.s_addr = _context->getIp(hostname);

   if(sendTarget.sin_addr.s_addr == -1)
   {
      return -1;
   }

   return 0;
}
