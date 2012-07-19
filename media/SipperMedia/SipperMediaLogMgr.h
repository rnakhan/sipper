#ifndef __SIPPER_MEDIA_LOGMGR_H__
#define __SIPPER_MEDIA_LOGMGR_H__

#pragma warning(disable: 4786)
#pragma warning(disable: 4503)

#include "SipperMediaLogger.h"
#include <pthread.h>

#include <string>
#include <vector>
#include <list>
#include <map>

typedef int (*AlarmReporterFunction)(int errCode, int troubleID, const char* alarmMsg);


class LogMgr
{
   public:

   //interface argument structure.
      class LogParam
      {
         public:

            std::string logFile;
            std::string logDir;
            int    logSize;
            Logger::LogLevel logLevel;

         public:
            
            LogParam()
            {
               logFile = "AppLog";
               logDir  = "/tmp";
               logSize = 1000000L;
               logLevel = Logger::TRACE;
            }
      };
      
      class LogCompParam
      {
         public:
            Logger::LogLevel logLevel;
      };
      
      class SourceFileRange
      {
         public:

            int from;
            int to;
      };
      
      class LogCompFileParam
      {
         public:

            std::vector<SourceFileRange> lineRanges;
      };


   public:

   //Log config file structure.

      class LogCfgComponentParam
      {
         public:

            Logger::LogLevel loglevel;
            std::map<std::string, LogCompFileParam> fileDet;

            LogCfgComponentParam()
            {
               loglevel = Logger::TRACE;
            }
      };

      class LogCfgFile
      {
         public:

            LogParam logMgrParam;
            std::map<std::string, LogCfgComponentParam> components;
      };

   private:

      std::string _subDir;

      std::string _logConfigFilename;
      LogCfgFile _cfgFile;

      bool _initStatus;

      class _logComponent
      {
         public:

            Logger::LogLevel loglevel;
            std::map<std::string, Logger *> loggerList;

            _logComponent()
            {
               loglevel = Logger::TRACE;
            }
      };

      LogParam _logParam;
      std::map<std::string, _logComponent> _components;

   public:

      void registerLogger(Logger *);
      void deregisterLogger(Logger *);

      void logMsg(const char *, const char *, va_list, bool dateChange = false);
      void raiseAlarm(const char *, va_list, int, int = 0);

   private:

      pthread_mutex_t _fileMutex;
      FILE *_fp;

      int _currSize;

      AlarmReporterFunction _almReptFunction;

   private:

      void _closeFile();
      void _renameFile();
      void _openFile();
      void _handleDateChange();

      void _reloadConfigFile();
      void _loadConfigFile();
      void _saveConfigFile();

      int _setLogParam(const LogParam&);
      int updateCronEntry();

   private:

      LogMgr();
      ~LogMgr();

   public:

      static LogMgr *_instance;
      static LogMgr &instance();
      static void destroy();

      //operation of dynamic selection is undefined on using this API to init
      //LogMgr.
      void init(const char *logFile, const char *logDir, 
                Logger::LogLevel level = Logger::ERRORS,
                int logSize = 1000000);

      //For Dynamic selection.
      void init(const char *logConfigFile, AlarmReporterFunction = NULL);

      //Parameter accessors..
      void loadExternalConfigFile(const char *);
      void setAlarmManager(AlarmReporterFunction); 

      int setLogParam(const LogParam&);
      void getLogParam(LogParam &);

      void getComponentParam(const char *, LogCompParam &);
      void setComponentParam(const char *, const LogCompParam&);

      void getComponents(std::list<std::string> &);
      void getComponentFiles(const char *, std::list<std::string> &);

      void getComponentFileParams(const char *, const char *, 
                                  LogCompFileParam&);
      void setComponentFileParams(const char *, const char *,
                                  const LogCompFileParam& );
      void setDefaultLogOption();
      friend class Logger;
};

#endif
