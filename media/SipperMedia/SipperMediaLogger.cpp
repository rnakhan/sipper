#include "SipperMediaLogger.h"
#include "SipperMediaLogMgr.h"
#include "SipperMediaPortable.h"

using namespace std;

const char * Logger::_severity[] = {"TRC", "VER", "WRN", "ERR", "ALM", "ALW"};
int Logger::counter = 0;

Logger::Logger(const char *component, const char *filename, LogMgr *logMgr)
{
   _initialize(component, filename, logMgr);
}

void Logger::_initialize(const char *component, const char *infilename, 
                         LogMgr *logMgr) 
{
   if(logMgr == NULL)
   {
      _logMgr = &LogMgr::instance();
   }
   else
   {
      _logMgr = logMgr;
   }
   _component = new char[strlen(component) + 1];
   strcpy(_component, component);

   const char *filename = strrchr(infilename, '\\');

   if(filename == NULL)
   {
      filename = infilename;
   }
   else
   {
      filename++; 
   }

   const char *currFile = strrchr(filename, '/');

   if(currFile == NULL)
   {
      currFile = filename;
   }
   else
   {
      currFile++; 
   }

   _filename = new char[strlen(filename) + 1];
   strcpy(_filename, currFile);

   _currLevel = TRACE;

   _no_of_ranges = 0;

   _calculateTimeDiff();

   _logMgr->registerLogger(this);
}

Logger::Logger(const char *filename) 
{
   LogMgr &mgr = LogMgr::instance();
   int currNo = 0;

   pthread_mutex_lock(&mgr._fileMutex);
   currNo = counter++;
   pthread_mutex_unlock(&mgr._fileMutex);

   char comp[60];
   sprintf(comp, "Template_%d", currNo);
   _initialize(comp, filename, &mgr);
}

void Logger::_calculateTimeDiff()
{
   struct timeval currTime;
   SipperMediaPortable::getTimeOfDay(&currTime);

   __int64 refHrTime = SipperMediaPortable::gethrtime() / 1000000;
   __int64 refGetTime = currTime.tv_sec;
   refGetTime *= 1000;
   refGetTime += (currTime.tv_usec / 1000);

   struct tm local;
   time_t currsec = time(NULL);
   localtime_r(&currsec, &local);

   struct tm timeStruct;

   timeStruct.tm_year = 70;
   timeStruct.tm_mon = 0;
   timeStruct.tm_mday = 1;
   timeStruct.tm_hour = 0;
   timeStruct.tm_min = 0;
   timeStruct.tm_sec = 0;
   timeStruct.tm_isdst = local.tm_isdst;

   __int64 timeZoneDiff = mktime(&timeStruct);
   timeZoneDiff *= 1000;

   struct tm nextday;
   currsec += 86400;

   do
   {
      localtime_r(&currsec, &nextday);
      currsec += 3600; //To takecare of time shift during daytime saving.
   }while(local.tm_mday == nextday.tm_mday);

   nextday.tm_hour = 0;
   nextday.tm_min = 0;
   nextday.tm_sec = 0;

   __int64 nextDayStart = mktime(&nextday);
   nextDayStart *= 1000;
   nextDayStart -= timeZoneDiff;

   pthread_mutex_lock(&_logMgr->_fileMutex);
   _milliDiff = timeZoneDiff + refHrTime - refGetTime ;
   _tomorrowStart = nextDayStart;
   pthread_mutex_unlock(&_logMgr->_fileMutex);
}

Logger::~Logger()
{
   if(_logMgr != NULL)
   {
      _logMgr->deregisterLogger(this);
   }

   delete []_filename;
   delete []_component;
}

void Logger::logMsg(LogLevel level, int lineno, int errNo, 
                    const char *formatStr, ...)
{
   va_list varg;
   va_start(varg, formatStr);

   _logMsg(level, lineno, errNo, formatStr, varg);

   if(level == ALARM)
   {
      _logMgr->raiseAlarm(formatStr, varg, errNo);
   }

   va_end(varg);
}

void Logger::logMsgArg(LogLevel level, int lineno, int errNo, 
                       const char *formatStr, va_list varg)
{
   _logMsg(level, lineno, errNo, formatStr, varg);

   if(level == ALARM)
   {
      _logMgr->raiseAlarm(formatStr, varg, errNo);
   }
}

void Logger::logAlarm(int lineno, int errorcode, int troubleid, 
                      const char *formatStr, ...)
{
   va_list varg;
   va_start(varg, formatStr);

   _logMsg(ALARM, lineno, errorcode, formatStr, varg);
   _logMgr->raiseAlarm(formatStr, varg, errorcode, troubleid);

   va_end(varg);
}

void Logger::logAlarmArg(int lineno, int errorcode, int troubleid, 
                         const char *formatStr, va_list varg)
{
   _logMsg(ALARM, lineno, errorcode, formatStr, varg);
   _logMgr->raiseAlarm(formatStr, varg, errorcode, troubleid);
}

void Logger::_logMsg(LogLevel level, int lineno, int errNo, 
                     const char *formatStr, va_list varg, bool to_log)
{
   if(!to_log)
   {
      for(int idx = 0; idx < _no_of_ranges; idx++)
      {
         if(_rangeList[idx].from <= lineno && _rangeList[idx].to >= lineno)
         {
            to_log = true;
            break;
         }
      }
   }

   if(!to_log)
   {
      if(level < _currLevel)
      {
         return;
      }
   }

   char logHead[600];

   __int64 currMilliTime = (SipperMediaPortable::gethrtime() / 1000000L) - _milliDiff;

   time_t tv_sec = currMilliTime / 1000L;
   int tv_msec = (int) (currMilliTime - (tv_sec * 1000L));

   struct tm fmt;
   fmt.tm_sec = tv_sec % 60;
   fmt.tm_min = (tv_sec % 3600) / 60;
   fmt.tm_hour = (tv_sec % 86400) / 3600;

#ifndef __UNIX__
   sprintf(logHead, "\n%s %d %d %d:%d:%d-%d %s %s-%d ", _severity[level], 
           errNo, (int) pthread_self().p, fmt.tm_hour, fmt.tm_min, fmt.tm_sec, 
           tv_msec, _component, _filename, lineno);
#else
   sprintf(logHead, "\n%s %d %d %d:%d:%d-%d %s %s-%d ", _severity[level], 
           errNo, (int) pthread_self(), fmt.tm_hour, fmt.tm_min, fmt.tm_sec, 
           tv_msec, _component, _filename, lineno);
#endif

   if(_tomorrowStart < currMilliTime)
   {
      _calculateTimeDiff();
      _logMgr->logMsg(logHead, formatStr, varg, true);
   }
   else
   {
      _logMgr->logMsg(logHead, formatStr, varg);
   }
}

