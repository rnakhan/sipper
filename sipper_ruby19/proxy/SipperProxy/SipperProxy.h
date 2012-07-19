#ifndef __SIPPER_PROXY_H__
#define __SIPPER_PROXY_H__

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#include <map>
#include <string>
#include "SipperProxyStatMgr.h"

struct DnsEntry
{
   public:

      time_t entryTime;

      int entryCount;
      in_addr_t addr[5];

   public:

      DnsEntry()
      {
         entryTime = 0;
         entryCount = 0;
         for(unsigned int idx = 0; idx < 5; idx++)
         {
            addr[idx] = -1;
         }
      }
};

typedef std::map<std::string, DnsEntry> DnsMap;
typedef DnsMap::const_iterator DnsMapCIt;
typedef DnsMap::iterator DnsMapIt;

class DnsCache
{
   private:

      DnsMap _entries;
      time_t _lastCheckTime;

   public:

      DnsCache();

      in_addr_t getIp(const std::string &hostname);
      void checkCache();

      void addEntry(const std::string &name, in_addr_t ip, bool removable = false);
};

class SipperDomain
{
   public:

      std::string name;
      in_addr_t ip;
      unsigned short port;

      std::string hostpart;
};

class SipperProxyMsg;
class SipperProxy
{
   private:

      int _sipperOutSocket;
      int _sipperInSocket;

      struct sockaddr_in *_inAddr;
      struct sockaddr_in *_outAddr;

      std::string _inStrPort;
      unsigned short _inPort;
      unsigned short _outPort;

      std::string _inStrAddr;
      std::string _outStrAddr;

      DnsCache _dnsCache;

      SipperProxyStatMgr *_statMgr;

   public:

      unsigned int _numOfSipperDomain;
      unsigned int _toSendIndex;

      SipperDomain *sipperDomains;

      std::string pxyStrIp;     //68.178.254.124
      std::string pxyStrDomain; //sip.agnity.com
      std::string pxyStrPort;   //5060

      std::string pxyRouteHdr;
      std::string pxyPathHdr;
      std::string pxyRecordRouteHdr;
      std::string pxyUriHost;   //sip.agnity.com:5060
      std::string pxyUriIPHost; //68.178.254.124:5060
      std::string pxyViaHdr;

      bool processMaxForward;
      bool incPathHdr;
      bool incRecordRouteHdr;
      bool enableStatistics;

      in_addr_t outboundPxyIp;
      unsigned short outboundPxyPort;

   public:

      SipperProxy();
      ~SipperProxy();
      void start();

      SipperDomain * getSipperDomain();

      in_addr_t getIp(const std::string &hostname)
      {
         return _dnsCache.getIp(hostname);
      }

      bool isSipperDomain(in_addr_t addr, unsigned short port);

      void setupStatistics(SipperProxyMsg *msg);

};

#define MAX_PROXY_MSG_LEN 0xFFFF

class SipperProxyMsg
{
   public:

      char buffer[MAX_PROXY_MSG_LEN + 1];
      int  bufferLen;
      char incomingMsg[MAX_PROXY_MSG_LEN + 1];
      int  incomingMsgLen;

      bool isRequest;

      char incomingBranch[301];
      char outgoingBranch[301];
      char msgName[101];
      char respReq[101];
      char callId[301];

      struct sockaddr_in recvSource;
      int recvSocket;

      struct sockaddr_in sendTarget;
      int sendSocket;

      char *hdrStart;

      SipperProxy *_context;

      char *_routeStart;

      bool msgFromSipper;
      bool msgToSipper;

   public:

      void processMessage(SipperProxy *context);

   private:

      void _processResponse();
      void _processRequest();

      int _removeFirstVia();
      int _setTargetFromFirstVia();

      int _getFirstVia(char *&viaStart, char *&viaValStart);
      int _getCallId();
      int _getCSeqMethod();

      void _removeData(char *from, char *to);
      void _addToBuffer(char *startPos, const char *insData, int len);
      void _replaceData(char *from, char *to, const char *insData, int len);

      int _processMaxForward();
      int _processViaRport();
      void _addViaHeader();
      void _addPathHeader();
      void _addRecordRouteHeader();

      int _getFirstRoute(char *&routeStart, char *&routeValStart);
      int _getFirstRoute(char *&routeStart, char *&routeEnd, bool &singleHdr,
                         char *&routeValStart, char *&routeValEnd);
      int _getLastRoute(char *&routeStart, char *&routeEnd, bool &singleHdr,
                        char *&routeValStart, char *&routeValEnd);

      bool _isRegisterRequest();
      bool _isRoutePresent();
      bool _isReqURIContainsProxyDomain(bool &lrFlag);
      void _moveLastRouteToReqURI();
      void _moveFirstRouteToReqURI();
      void _moveFirstRouteToReqURIAndReqURIToLastRoute();
      void _removeFirstRouteIfProxyDomain();
      int _setTargetFromFirstRoute(bool &lrFlag);
      int _setTargetFromReqURI();
      int _setTargetFromSipperDomain();
      int _setTargetFromOutboundPxy();
};

#endif
