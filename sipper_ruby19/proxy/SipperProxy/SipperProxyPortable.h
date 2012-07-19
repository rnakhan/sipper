#ifndef __SIPPER_PROXY_PORTABLE_H__
#define __SIPPER_PROXY_PORTABLE_H__

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#define _CRT_SECURE_NO_WARNINGS 1
#else
typedef long long __int64;
#include <errno.h>
#endif

#include <string>

class SipperProxyPortable
{
public:
   static void getTimeOfDay(struct timeval *tv);
   static bool isGreater(struct timeval *time1, struct timeval *time2);
   static struct timeval getTimeDifference(struct timeval *time1, struct timeval *time2);
   static int getErrorCode();
   static __int64 gethrtime();

   static void toUpper(std::string &input);
   static void trim_right(std::string & s, const std::string & t = " \r\n\t");
   static void trim_left(std::string & s, const std::string & t = " \r\n\t");
   static void trim(std::string & s, const std::string & t = " \r\n\t");

   static void setNonBlocking(int fd);
   static void setTcpNoDelay(int fd);
   static void disconnectSocket(int &fd);
   static std::string errorString();
};

#endif
