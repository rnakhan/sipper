#include "SipperMediaPortable.h"
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

void SipperMediaPortable::toUpper(std::string &input)
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

void SipperMediaPortable::trim_right(std::string &s, const std::string &t)
{ 
  std::string &d = s;
  std::string::size_type i (d.find_last_not_of (t));
  if (i == std::string::npos)
     d = "";
  else
   d.erase(i + 1) ; 
}  

void SipperMediaPortable::trim_left(std::string &s, const std::string &t) 
{ 
  s.erase (0, s.find_first_not_of (t)) ; 
}  

void SipperMediaPortable::trim(std::string &s, const std::string &t)
{ 
   trim_right(s, t);
   trim_left(s, t); 
}  // end of trim


void SipperMediaPortable::getTimeOfDay(struct timeval *tv)
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

__int64 SipperMediaPortable::gethrtime()
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

bool SipperMediaPortable::isGreater(struct timeval *time1, struct timeval *time2)
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

struct timeval SipperMediaPortable::getTimeDifference(struct timeval *time1, struct timeval *time2)
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


int SipperMediaPortable::getErrorCode()
{
#ifdef __UNIX__
   return errno;
#else
   return WSAGetLastError();
#endif
}
