#include "SipperProxyLogger.h"
LOG("Portable");

#include "SipperProxyPortable.h"
#include <stdio.h>

#ifndef __UNIX__
#if defined(_MSC_VER) || defined(__BORLANDC__)
#define EPOCHFILETIME (116444736000000000i64)
#else
#define EPOCHFILETIME (116444736000000000LL)
#endif
#include <windows.h>

#else
#include <sys/time.h>
#endif

#include <string>
#include <ctype.h>

#pragma warning(disable: 4786)

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#endif

void SipperProxyPortable::toUpper(std::string &input)
{
#if 1
   char *inputStr = (char *)input.c_str();

   while(*inputStr)
   {
      *inputStr = toupper(*inputStr);
      ++inputStr;
   }
#else
   std::transform(input.begin(), input.end(), input.begin(), 
                   (int(*)(int)) toupper);
#endif
}

void SipperProxyPortable::trim_right(std::string &s, const std::string &t)
{ 
  std::string &d = s;
  std::string::size_type i (d.find_last_not_of (t));
  if (i == std::string::npos)
     d = "";
  else
   d.erase(i + 1) ; 
}  

void SipperProxyPortable::trim_left(std::string &s, const std::string &t) 
{ 
  s.erase (0, s.find_first_not_of (t)) ; 
}  

void SipperProxyPortable::trim(std::string &s, const std::string &t)
{ 
   trim_right(s, t);
   trim_left(s, t); 
}  // end of trim


void SipperProxyPortable::getTimeOfDay(struct timeval *tv)
{
#ifndef __UNIX__
   FILETIME        ft;
   LARGE_INTEGER   li;
   __int64         t;

   if (tv)
   {
      GetSystemTimeAsFileTime(&ft);
      li.LowPart  = ft.dwLowDateTime;
      li.HighPart = ft.dwHighDateTime;
      t  = li.QuadPart;       /* In 100-nanosecond intervals */
      t -= EPOCHFILETIME;     /* Offset to the Epoch time */
      t /= 10;                /* In microseconds */
      tv->tv_sec  = (long)(t / 1000000);
      tv->tv_usec = (long)(t % 1000000);
   }

#else
   gettimeofday(tv, NULL);
#endif
}

__int64 SipperProxyPortable::gethrtime()
{
#ifndef __UNIX__
   FILETIME        ft;
   LARGE_INTEGER   li;
   __int64         t;

   GetSystemTimeAsFileTime(&ft);
   li.LowPart  = ft.dwLowDateTime;
   li.HighPart = ft.dwHighDateTime;
   t  = li.QuadPart;       /* In 100-nanosecond intervals */
   t *= 100;

   return t;
#else
   struct timeval tv;
   gettimeofday(&tv, NULL);
   __int64 v1, v2;
   v1 = tv.tv_sec; v1 *= 1000000000LL;
   v2 = tv.tv_usec; v2 *= 1000;
   return v1 + v2;
#endif
}

bool SipperProxyPortable::isGreater(struct timeval *time1, struct timeval *time2)
{
   if(time1->tv_sec > time2->tv_sec)
   {
      return true;
   }

   if((time1->tv_sec == time2->tv_sec) && (time1->tv_usec > time2->tv_usec))
   {
      return true;
   }

   return false;
}

struct timeval SipperProxyPortable::getTimeDifference(struct timeval *time1, struct timeval *time2)
{
   struct timeval ret;

   ret.tv_sec = time1->tv_sec - time2->tv_sec;
   ret.tv_usec = time1->tv_usec - time2->tv_usec;

   while(ret.tv_usec < 0)
   {
      ret.tv_sec--;
      ret.tv_usec += 1000000;
   }
   
   return ret;
}


int SipperProxyPortable::getErrorCode()
{
#ifdef __UNIX__
   return errno;
#else
   return WSAGetLastError();
#endif
}

void SipperProxyPortable::setNonBlocking(int fd)
{
#ifdef __UNIX__
   int flags;

   if((flags = fcntl(fd, F_GETFL, 0)) < 0)
   {
     std::string errMsg = SipperProxyPortable::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error getting socket status. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   flags |= O_NONBLOCK;

   if(fcntl(fd, F_SETFL, flags) < 0)
   {
     std::string errMsg = SipperProxyPortable::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#else
   unsigned long flag = 1;
   if(ioctlsocket(fd, FIONBIO, &flag) != 0)
   {
     std::string errMsg = SipperProxyPortable::errorString();

      printf("Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#endif
}

void SipperProxyPortable::disconnectSocket(int &fd)
{
   if(fd != -1)
   {
#ifdef __UNIX__
      close(fd);
#else
      closesocket(fd);
#endif
      fd = -1;
   }
}

void SipperProxyPortable::setTcpNoDelay(int fd)
{
   int flag = 1;
#ifdef __UNIX__
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(int)) < 0)
#else
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (const char *)&flag, sizeof(int)) < 0)
#endif
   {
     std::string errMsg = SipperProxyPortable::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error disabling Nagle algorithm. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   logger.logMsg(ALWAYS_FLAG, 0, "Successfully changed the Sock[%d] options.\n",
          fd);
}

std::string SipperProxyPortable::errorString()
{
   std::string ret = (const char *) strerror(SipperProxyPortable::getErrorCode());
   return ret;
}

