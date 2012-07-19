#ifndef __SIPPER_MEDIA_CONTROLLER_H__
#define __SIPPER_MEDIA_CONTROLLER_H__


#include "SipperMedia.h"
#include <map>
#include <string>

class SipperMediaListener;
class SipperMediaController
{
private:

   unsigned int _callbackMSec;
   typedef std::map<int, SipperMedia *> SipperMediaMap;
   typedef SipperMediaMap::iterator SipperMediaMapIt;

   std::string _controllerIp;

   SipperMediaMap _mediaMap;
   int _mediaSeq;

   int commandLen;
   std::string commandBuf;

   int _sock;
   bool _shutdownFlag;

public:

   SipperMediaListener *listener;

public:

   static int readSocket(int sock, void *buf, unsigned int toRead);
   static int sendSocket(int sock, const void *buf, unsigned int toWrite);

   SipperMediaController();
   ~SipperMediaController();

   void shutdown();
   void sendEvent(const std::string &event);
   void handleRequest(int commandSock);
   int handleCommand(int commandSock, fd_set &readfds);
   void handleTimeout(struct timeval *currtime, struct timeval *nextcallbacktime);
   std::string executeCommand(std::string &command);

   std::string getIp()
   {
      return _controllerIp;
   }
};

#endif
