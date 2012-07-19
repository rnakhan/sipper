#ifndef __SIPPER_MEDIA_LOGGER_H__
#define __SIPPER_MEDIA_LOGGER_H__

#pragma warning(disable: 4786)
#pragma warning(disable: 4503)

#include "SipperMediaPortable.h"

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <sys/time.h>
#endif
#include <stdarg.h>
#include <stdio.h>

#define MAX_RANGE_FILE 20

class LogMgr;

class Logger
{
   public:

      enum LogLevel
      {
         TRACE,
         VERBOSE,
         WARNING,
         ERRORS,
         ALARM,
         ALWAYS
      };

   private:

      static const char *_severity[];

      struct _lineRanges
      {
         int from;
         int to;
      };

      LogMgr *_logMgr;

      char *_component;
      char *_filename;

      //Populated by LogMgr.
      LogLevel _currLevel;

      struct _lineRanges _rangeList[MAX_RANGE_FILE];
      int _no_of_ranges;

      bool _isLineRange;

      //For efficient time calculation.
      __int64 _milliDiff;
      __int64 _tomorrowStart;

      void _calculateTimeDiff();
      void _initialize(const char *, const char *, LogMgr *);

   public:

      friend class LogMgr;

      Logger(const char *, const char *, LogMgr * = NULL); 
      ~Logger();

      void logMsg(LogLevel, int, int, const char *, ...);
      void logMsgArg(LogLevel, int, int, const char *, va_list varg);
      void logAlarm(int lineno, int errorcode, int troubleid, const char *, 
                    ...);
      void logAlarmArg(int lineno, int errorcode, int troubleid, const char *, 
                       va_list varg);

   protected:
      
      void _logMsg(LogLevel, int, int, const char *, va_list , bool = false);

      Logger(const char *);

      static int counter;
};

#define LogTrace(errCode, errMsg) logger.logMsg(Logger::TRACE, __LINE__, \
                                                errCode, errMsg);
#define LogVerbose(errCode, errMsg) logger.logMsg(Logger::VERBOSE, __LINE__, \
                                                  errCode, errMsg);
#define LogWarning(errCode, errMsg) logger.logMsg(Logger::WARNING, __LINE__, \
                                                  errCode, errMsg);
#define LogError(errCode, errMsg) logger.logMsg(Logger::ERRORS, __LINE__, \
                                                errCode, errMsg);
#define LogAlarm(errCode, errMsg) logger.logMsg(Logger::ALARM, __LINE__, \
                                                errCode, errMsg);
#define LogAlarmInfo(errCode, troubleID, errMsg) logger.logAlarm(__LINE__, \
                                                errCode, troubleID, errMsg);
#define LogAlways(errCode, errMsg) logger.logMsg(Logger::ALWAYS, __LINE__, \
                                                 errCode, errMsg);

#define TRACE_FLAG   Logger::TRACE,   __LINE__
#define VERBOSE_FLAG Logger::VERBOSE, __LINE__
#define WARNING_FLAG Logger::WARNING, __LINE__
#define ERROR_FLAG   Logger::ERRORS,   __LINE__
#define ALARM_FLAG   Logger::ALARM,   __LINE__
#define ALWAYS_FLAG  Logger::ALWAYS,  __LINE__

#define LOG(x) static Logger logger((x), __FILE__)
#define LOGTEMP Logger((const char *) __FILE__)

#endif
