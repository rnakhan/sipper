#ifndef __SIPPER_MEDIA_H__
#define __SIPPER_MEDIA_H__

#pragma warning(disable: 4786)

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#include "SipperMediaCodec.h"
#include "SipperMediaPortable.h"

#include <string>
#include <set>
#include <map>
#include <list>

typedef std::map<int, SipperMediaCodec *> SipperMediaCodecMap;
typedef SipperMediaCodecMap::iterator SipperMediaCodecMapIt;

typedef std::set<std::string> StrSet;
typedef StrSet::const_iterator StrSetCIt;
typedef std::map<std::string, std::string> ParamMap;
typedef ParamMap::const_iterator ParamMapCIt;

class SipperMediaController;
class SipperMedia
{
public:
   enum MediaStatus
   {
      SENDONLY = 1,
      RECVONLY,
      SENDRECV,
      INACTIVE
   };
public:

   SipperMediaController *controller;
   int id;
   MediaStatus _mediaStatus;

   SipperMedia()
   {
      id = 0;
      _mediaStatus = SipperMedia::INACTIVE;
   }

   virtual ~SipperMedia() {};
   virtual void setReadFd(fd_set &readfds, int &maxfd) = 0;
   virtual void checkData(struct timeval &currtime, fd_set &readfds) = 0;
   virtual void handleTimer(struct timeval &currtime) = 0;

   virtual std::string setSendInfo(ParamMap &params) = 0;
   virtual std::string setProperty(ParamMap &params) = 0;
   virtual std::string setMediaStatus(const std::string &status) = 0;
   virtual std::string getRecvInfo() = 0;

   static SipperMedia * createMedia(ParamMap &params);
   virtual void sendEvent(const std::string &event);
};


class SipperRTPMedia : public SipperMedia
{
   unsigned short _sendPort;
   unsigned int _sendIP;
   unsigned int _keepAliveIntervalInSec;
   struct timeval _lastKeepAliveSentTime;
   
   bool _portFromMgrFlag;
   int _recvSocket;

   SipperMediaCodecMap _codecMap;

public:

   SipperMediaRTPHeader lastSentHeader;
   SipperMediaRTPHeader lastRecvHeader;
   int lastDtmfTimestamp;

public:

   ~SipperRTPMedia();

   virtual void setReadFd(fd_set &readfds, int &maxfd);
   virtual void checkData(struct timeval &currtime, fd_set &readfds);
   virtual void handleTimer(struct timeval &currtime);

   virtual std::string setSendInfo(ParamMap &params);
   virtual std::string setProperty(ParamMap &params);
   virtual std::string setMediaStatus(const std::string &status);
   virtual std::string getRecvInfo();

   virtual void sendRTPPacket(SipperMediaRTPHeader &header, unsigned char *dataptr, unsigned int len);

public:

   SipperRTPMedia(unsigned int ipaddr, unsigned short recvPort);

   std::string clearCodecs();
   std::string addCodecs(ParamMap &params);
   std::string sendDtmf(ParamMap &params);

   std::string toString();
};

#endif
