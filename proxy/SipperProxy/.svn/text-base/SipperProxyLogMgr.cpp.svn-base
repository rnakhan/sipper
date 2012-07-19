#include "SipperProxyLogMgr.h"
#include "SipperProxyPortable.h"
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include <stdarg.h>
#ifndef __UNIX__
#include <direct.h>
#endif

#define TEMP_FILE "/tmp/tempLogMgr"

using namespace std;

LogMgr * LogMgr::_instance = NULL;

void LogMgr::registerLogger(Logger *currLogger)
{
   string component = currLogger->_component;
   string filename = currLogger->_filename;

   pthread_mutex_lock(&_fileMutex);

   if(_components.find(component) == _components.end())
   {
      _components[component].loglevel = _logParam.logLevel;
   }

   if(_components[component].loggerList.find(filename) != 
      _components[component].loggerList.end())
   {
      printf("Multiple registration with same component-filename. "
             "[%s] [%s]\n", component.c_str(), filename.c_str());
      fflush(stdout);
      exit(1);
   }

   _components[component].loggerList[filename] = currLogger;

   currLogger->_currLevel = _logParam.logLevel;

   if(_initStatus)
   {
      if(_cfgFile.components.find(component) != _cfgFile.components.end())
      {
         LogCfgComponentParam &compParam = _cfgFile.components[component];

         currLogger->_currLevel = compParam.loglevel;
         _components[component].loglevel = compParam.loglevel;

         if(compParam.fileDet.find(filename) != compParam.fileDet.end())
         {
            vector<SourceFileRange> &ranges = 
                         compParam.fileDet[filename].lineRanges;
            currLogger->_no_of_ranges = ranges.size();

            for(int idx = 0; idx < currLogger->_no_of_ranges; idx++)
            {
               currLogger->_rangeList[idx].from = ranges[idx].from;
               currLogger->_rangeList[idx].to = ranges[idx].to;
            }
         }
      }
   }

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::deregisterLogger(Logger *currLogger)
{
   string component = currLogger->_component;
   string filename  = currLogger->_filename;

   pthread_mutex_lock(&_fileMutex);

   _components[component].loggerList.erase(filename); 

   if(_components[component].loggerList.empty())
   {
      _components.erase(component);
   }

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::logMsg(const char *header, const char *mesgFormat, va_list args,
                    bool datechange)
{
   pthread_mutex_lock(&_fileMutex);

   _currSize += fprintf(_fp, header);
   _currSize += vfprintf(_fp, mesgFormat, args);
   fflush(_fp);

   if(datechange)
   {
      _handleDateChange();
   }

   if(_currSize > _logParam.logSize)
   {
      _closeFile();
      _renameFile();
      _openFile();
   }

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::raiseAlarm(const char *mesgFormat, va_list args, int errnos, 
                        int troubleID)
{
	//Pl pass proper and defined error codes as per BpExceptionCode.h
   pthread_mutex_lock(&_fileMutex);
   if(_almReptFunction != NULL)
   {
      AlarmReporterFunction myfunccopy = _almReptFunction;
      char *mesg = new char[2048];
      mesg[2047] = '\0';
#ifndef __UNIX__
      _vsnprintf(mesg, 2047, mesgFormat, args);
#else
	  vsnprintf(mesg, 2047, mesgFormat, args);
#endif

      pthread_mutex_unlock(&_fileMutex);
      myfunccopy(errnos, troubleID, mesg);
      pthread_mutex_lock(&_fileMutex);

      delete []mesg;
   }
   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::_closeFile()
{
   if(_fp != NULL && _fp != stdout)
   {
      fflush(_fp);
      fclose(_fp);
   }

   _fp = NULL;
   return;
}

void LogMgr::_renameFile()
{
   if(_fp == stdout)
   {
      _currSize = 0;
      return;
   }

   string newFilename = _logParam.logDir + _subDir + _logParam.logFile;
   string oldFilename = newFilename;
   char ext[60];

   struct timeval currTime;
   struct tm localTime;

   SipperProxyPortable::getTimeOfDay(&currTime);
#ifndef __UNIX__
   localtime_r((const time_t *)&currTime.tv_sec, &localTime);
#else
   localtime_r(&currTime.tv_sec, &localTime);
#endif

   int timeChars = strftime(ext, 60, "_%H_%M_%S_", &localTime);
   sprintf(ext + timeChars, "%03d", currTime.tv_usec/1000);

   newFilename += ext;

   rename(oldFilename.c_str(), newFilename.c_str());

   return;
}

void LogMgr::_handleDateChange()
{

   char newsubdir[60];

   struct timeval currTime;
   struct tm localTime;

   SipperProxyPortable::getTimeOfDay(&currTime);
#ifndef __UNIX__
   localtime_r((const time_t *)&currTime.tv_sec, &localTime);
#else
   localtime_r(&currTime.tv_sec, &localTime);
#endif

   int timeChars = strftime(newsubdir, 60, "%m_%d_%y", &localTime);
   strcpy(newsubdir + timeChars, "/");

   if(_subDir != newsubdir)
   {
      _subDir = newsubdir;

      string newlogDir = _logParam.logDir + _subDir;

#ifndef __UNIX__
      _mkdir(_logParam.logDir.c_str());
      _mkdir(newlogDir.c_str());
#else
      mkdir(_logParam.logDir.c_str(), 0755);
      mkdir(newlogDir.c_str(), 0755);
#endif
      _closeFile();
      _openFile();
   }


   return;
}

void LogMgr::_openFile()
{
   _closeFile();

   string newFilename = _logParam.logDir + _subDir + _logParam.logFile;
   //cout << "File Name to open : " << newFilename << endl;

   _fp = fopen(newFilename.c_str(), "a");

   if(_fp == NULL)
   {
      _fp = stdout;
      _currSize = 0;

      //cout << "Log file opening error : " << newFilename << endl;

      fprintf(_fp, "Log file opening error\n");

      fflush(_fp);

      pthread_mutex_unlock(&_fileMutex);
      raiseAlarm("Unable to open log file", NULL, -1);
      pthread_mutex_lock(&_fileMutex);

      return;
   }

   struct stat curr_stat;

   if(stat(newFilename.c_str(), &curr_stat) != 0)
   {
      _closeFile();
      _fp = stdout;
      _currSize = 0;

      //cout << "Error getting file status" << endl;

      fprintf(_fp, "Error getting file status \n");
      fflush(_fp);

      pthread_mutex_unlock(&_fileMutex);
      raiseAlarm("Unable to get log file status", NULL, -1);
      pthread_mutex_lock(&_fileMutex);

      return;
   }

   _currSize = curr_stat.st_size;
   return;
}

LogMgr::LogMgr()
{
   _initStatus = false;
   pthread_mutex_init(&_fileMutex, NULL);
   _fp = stdout;
   _currSize = 0;
   _almReptFunction = NULL;
}

LogMgr::~LogMgr()
{
   _closeFile();

   map<string, _logComponent>::iterator compit; 

   for(compit = _components.begin(); compit != _components.end(); compit++)
   {
      map<string, Logger *> &logger = compit->second.loggerList;
      map<string, Logger *>::iterator loggerit;

      for(loggerit = logger.begin(); loggerit != logger.end(); loggerit++)
      {
         loggerit->second->_logMgr = NULL;
      }
   }

   pthread_mutex_destroy(&_fileMutex);
}

LogMgr & LogMgr::instance()
{
   if(_instance == NULL)
   {
      _instance = new LogMgr;
   }

   return *_instance;
}

void LogMgr::destroy()
{
   if(_instance != NULL)
   {
      delete _instance;
   }

   _instance = NULL;
   return;
}

void LogMgr::init(const char *logFile, const char *logDir, 
                  Logger::LogLevel level, int logSize)
{
   pthread_mutex_lock(&_fileMutex);
   _cfgFile.logMgrParam.logFile = logFile;
   _cfgFile.logMgrParam.logDir  = logDir;
   _cfgFile.logMgrParam.logLevel = level;
   _cfgFile.logMgrParam.logSize = logSize;

   if(logDir[strlen(logDir) - 1] != '/')
   {
      _cfgFile.logMgrParam.logDir += "/";
   }

   _setLogParam(_cfgFile.logMgrParam);


   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::loadExternalConfigFile(const char *externalCfgFile)
{
   pthread_mutex_lock(&_fileMutex);

   string prevConfigFile = _logConfigFilename;
   _logConfigFilename = externalCfgFile;

   _reloadConfigFile();

   _logConfigFilename = prevConfigFile;
   _saveConfigFile();

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::init(const char *logConfigFile, AlarmReporterFunction myalm)
{
   pthread_mutex_lock(&_fileMutex);

   _almReptFunction = myalm;

   _logConfigFilename = logConfigFile;
   _reloadConfigFile();

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::setAlarmManager(AlarmReporterFunction myalm)
{
   pthread_mutex_lock(&_fileMutex);
   _almReptFunction = myalm;
   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::_reloadConfigFile()
{
   _cfgFile.components.clear();
   _loadConfigFile();

   LogParam &inParam = _cfgFile.logMgrParam;

   if((inParam.logFile != _logParam.logFile) ||
      (inParam.logDir != _logParam.logDir)   ||
      ((inParam.logSize != _logParam.logSize) &&
       (inParam.logSize < _currSize)))
   {
      _closeFile();
      _renameFile();

      _logParam.logFile = inParam.logFile;
      _logParam.logDir  = inParam.logDir;
      _logParam.logSize = inParam.logSize;
      
      _handleDateChange();
      _openFile();
   }

   if(inParam.logSize != _logParam.logSize)
   {
      _logParam.logSize = inParam.logSize;
   }

   _logParam.logLevel = inParam.logLevel;

   {
      //Sets the loglevel.
      map<string, _logComponent>::iterator compIt;

      for(compIt = _components.begin(); compIt != _components.end(); compIt++)
      {
         _logComponent &currComp = compIt->second;
   
         currComp.loglevel = _logParam.logLevel;
   
         map<string, Logger *>::iterator fileIt;
   
         for(fileIt = currComp.loggerList.begin(); 
             fileIt != currComp.loggerList.end(); fileIt++)
         {
            fileIt->second->_currLevel = _logParam.logLevel;
         }
      }
   }

   map<string, LogCfgComponentParam>::iterator compIt;
   map<string, LogCfgComponentParam> &components = _cfgFile.components;

   for(compIt = components.begin(); compIt != components.end(); compIt++)
   {
      LogCfgComponentParam &compParam = compIt->second;
      const string &currComp = compIt->first;

      if(_components.find(currComp) == _components.end())
      {
         continue;
      }

      _components[currComp].loglevel = compParam.loglevel;

      map<string, Logger *>::iterator loggerIt;
      for(loggerIt = _components[currComp].loggerList.begin();
          loggerIt != _components[currComp].loggerList.end(); loggerIt++)
      {
         loggerIt->second->_currLevel = compParam.loglevel;
      }

      map<string, LogCompFileParam>::iterator fileIt;

      for(fileIt = compParam.fileDet.begin(); fileIt != compParam.fileDet.end();
          fileIt++)
      {
         const string &currFile = fileIt->first;
         vector<SourceFileRange> &ranges = fileIt->second.lineRanges;

         if(_components[currComp].loggerList.find(currFile) !=
            _components[currComp].loggerList.end())
         {
            Logger *currLogger = _components[currComp].loggerList[currFile];

            for(unsigned int idx = 0; idx < ranges.size(); idx++)
            {
               currLogger->_rangeList[idx].from = ranges[idx].from;
               currLogger->_rangeList[idx].to = ranges[idx].to;
            }

            currLogger->_no_of_ranges = ranges.size();
         }
      }
   }
}

int
LogMgr::_setLogParam(const LogParam &inParam)
{
   if((inParam.logFile != _logParam.logFile) ||
      (inParam.logDir != _logParam.logDir)   ||
      ((inParam.logSize != _logParam.logSize) &&
       (inParam.logSize < _currSize)))
   {
      _closeFile();
      _renameFile();

      LogParam oldLogParam = _logParam;

      _logParam.logFile = inParam.logFile;
      _logParam.logDir  = inParam.logDir + "/";
      _logParam.logSize = inParam.logSize;
      
      string newlogDir = _logParam.logDir + _subDir;

#ifdef __UNIX__
	  mkdir(newlogDir.c_str(), 0755);
#else
	  _mkdir(newlogDir.c_str());
#endif
/*
      int ret;
      string mkdirStr = "mkdir -p " + newlogDir + " >/dev/null 2> " + TEMP_FILE;
      ret = system(mkdirStr.c_str());
      FILE* fpTemp = fopen(TEMP_FILE,"r");
      char temp[50];
      if((-1 == ret) || 
	 (NULL != fgets(temp,49,fpTemp)))
      {
	//cout << "Directories creation problem" << endl;

      	_logParam.logFile = oldLogParam.logFile;
      	_logParam.logDir  = oldLogParam.logDir;
      	_logParam.logSize = oldLogParam.logSize;
        _openFile();

        fclose(fpTemp);
	return -1;
      }

      fclose(fpTemp);*/
      _openFile();
   }

   if(inParam.logSize != _logParam.logSize)
   {
      _logParam.logSize = inParam.logSize;
   }

   if(inParam.logLevel == Logger::ALWAYS)
   {
      return 0;
   }

   if(inParam.logLevel != _logParam.logLevel)
   {
      map<string, _logComponent>::iterator compIt;

      for(compIt = _components.begin(); compIt != _components.end(); compIt++)
      {
         _logComponent &currComp = compIt->second;

         if(currComp.loglevel == _logParam.logLevel)
         {
            currComp.loglevel = inParam.logLevel;

            map<string, Logger *>::iterator fileIt;

            for(fileIt = currComp.loggerList.begin(); 
                fileIt != currComp.loggerList.end(); fileIt++)
            {
               fileIt->second->_currLevel = inParam.logLevel;
            }
         }
      }

      map<string, LogCfgComponentParam>::iterator cfgCompIt;

      for(cfgCompIt = _cfgFile.components.begin(); 
          cfgCompIt != _cfgFile.components.end(); cfgCompIt++)
      {
         LogCfgComponentParam &currComp = cfgCompIt->second;

         if(currComp.loglevel == _logParam.logLevel)
         {
            currComp.loglevel = inParam.logLevel;
         }
      }

      _logParam.logLevel = inParam.logLevel;
   }

   return 0;
}

int
LogMgr::updateCronEntry()
{
	char cmdStr[1024];
	sprintf(cmdStr,"cd ../scripts;./changeLogDirInCron.sh %s ; cd ../bin;",_logParam.logDir.c_str());
	int ret = system(cmdStr);
	return ret;
}

int 
LogMgr::setLogParam(const LogParam &inParam)
{
   pthread_mutex_lock(&_fileMutex);

   LogParam oldLogParam = inParam;

   if(-1 == _setLogParam(inParam))
   {
   	pthread_mutex_unlock(&_fileMutex);
	return -1;
   }

   // Change cron entry
   //
   if(-1 == this->updateCronEntry())
   {
        _closeFile();

      	_logParam.logFile = oldLogParam.logFile;
      	_logParam.logDir  = oldLogParam.logDir;
      	_logParam.logSize = oldLogParam.logSize;

        _openFile();
   	pthread_mutex_unlock(&_fileMutex);
	return -1;
   }
   //

   _cfgFile.logMgrParam = inParam;

   _saveConfigFile();

   pthread_mutex_unlock(&_fileMutex);
   return 0;
}

void LogMgr::getLogParam(LogParam &inParam)
{
   pthread_mutex_lock(&_fileMutex);
   inParam = _logParam;
   pthread_mutex_unlock(&_fileMutex);
   return;
}

void LogMgr::getComponentParam(const char *comp, LogCompParam &inParam)
{
   pthread_mutex_lock(&_fileMutex);

   if(_components.find(comp) != _components.end())
   {
      inParam.logLevel = _components[comp].loglevel;
   }

   pthread_mutex_unlock(&_fileMutex);
   return;
}

void LogMgr::setComponentParam(const char *comp, const LogCompParam &inParam)
{
   pthread_mutex_lock(&_fileMutex);

   if(_components.find(comp) != _components.end())
   {
      if(_components[comp].loglevel != inParam.logLevel)
      {
         _components[comp].loglevel = inParam.logLevel;

         map<string, Logger *>::iterator fileIt;

         for(fileIt = _components[comp].loggerList.begin(); 
             fileIt != _components[comp].loggerList.end(); fileIt++)
         {
            fileIt->second->_currLevel = inParam.logLevel;
         }
      }
   }

   _cfgFile.components[comp].loglevel = inParam.logLevel;
   _saveConfigFile();

   pthread_mutex_unlock(&_fileMutex);
   return;
}

void LogMgr::getComponents(list<string> &components)
{
   components.clear();

   pthread_mutex_lock(&_fileMutex);

   map<string, _logComponent>::iterator compIt;

   for(compIt = _components.begin(); compIt != _components.end(); compIt++)
   {
      components.push_back(compIt->first);
   }

   pthread_mutex_unlock(&_fileMutex);
   return;
}

void LogMgr::getComponentFiles(const char *comp, list<string> &files)
{
   files.clear();
   pthread_mutex_lock(&_fileMutex);

   if(_components.find(comp) != _components.end())
   {
      map<string, Logger *>::iterator fileIt;
      for(fileIt = _components[comp].loggerList.begin(); 
          fileIt != _components[comp].loggerList.end(); fileIt++)
      {
         files.push_back(fileIt->first);
      }
   }

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::getComponentFileParams(const char *comp, const char *file, 
                                    LogCompFileParam &inParam)
{
   inParam.lineRanges.clear();
   pthread_mutex_lock(&_fileMutex);

   if(_components.find(comp) != _components.end())
   {
      if(_components[comp].loggerList.find(file) != 
         _components[comp].loggerList.end())
      {
         Logger *currLogger = _components[comp].loggerList[file];

         for(int idx = 0; idx < currLogger->_no_of_ranges; idx++)
         {
            SourceFileRange range;
            range.from = currLogger->_rangeList[idx].from;
            range.to = currLogger->_rangeList[idx].to;

            inParam.lineRanges.push_back(range);
         }
      }
   }

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::setComponentFileParams(const char *comp, const char *file, 
                                    const LogCompFileParam &inParam)
{
   pthread_mutex_lock(&_fileMutex);

   if(_components.find(comp) != _components.end())
   {
      if(_components[comp].loggerList.find(file) != 
         _components[comp].loggerList.end())
      {
         Logger *currLogger = _components[comp].loggerList[file];
         const vector<SourceFileRange> &ranges = inParam.lineRanges;

         currLogger->_no_of_ranges = 0;

         for(unsigned int idx = 0; idx < ranges.size() && idx < MAX_RANGE_FILE; idx++)
         {
            currLogger->_rangeList[idx].from = ranges[idx].from;
            currLogger->_rangeList[idx].to = ranges[idx].to;
            currLogger->_no_of_ranges++;
         }
      }
   }

   if(_cfgFile.components.find(comp) == _cfgFile.components.end())
   {
      _cfgFile.components[comp].loglevel = _logParam.logLevel;
   }

   vector<SourceFileRange> &outranges = 
                            _cfgFile.components[comp].fileDet[file].lineRanges;
   outranges.clear();
   const vector<SourceFileRange> &inranges = inParam.lineRanges;

   for(unsigned int idx = 0; idx < inranges.size() && idx < MAX_RANGE_FILE; idx++)
   {
      outranges.push_back(inranges[idx]);
   }

   _saveConfigFile();

   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::setDefaultLogOption()
{
   pthread_mutex_lock(&_fileMutex);

   LogParam curr = _logParam;
   curr.logLevel = Logger::ERRORS;
   curr.logSize  = 1000000L;

   _setLogParam(curr);
   _cfgFile.logMgrParam = curr;

   map<string, _logComponent>::iterator compIt;

   for(compIt = _components.begin(); compIt != _components.end(); compIt++)
   {
      _logComponent &currComp = compIt->second;
      currComp.loglevel = _logParam.logLevel;

      map<string, Logger *>::iterator fileIt;

      for(fileIt = currComp.loggerList.begin(); 
          fileIt != currComp.loggerList.end(); fileIt++)
      {
         fileIt->second->_currLevel = _logParam.logLevel;
         fileIt->second->_no_of_ranges = 0;
      }
   }

   _cfgFile.components.clear();
   _saveConfigFile();
   pthread_mutex_unlock(&_fileMutex);
}

void LogMgr::_saveConfigFile()
{
   FILE *fp = fopen(_logConfigFilename.c_str(), "w");

   if(fp == NULL)
   {
      pthread_mutex_unlock(&_fileMutex);
      raiseAlarm("Unable to save config file", NULL, -2);
      pthread_mutex_lock(&_fileMutex);

      return;
   }

   fprintf(fp, "D LOGFILE %s\n", _cfgFile.logMgrParam.logFile.c_str());
   fprintf(fp, "D LOGDIR %s\n", _cfgFile.logMgrParam.logDir.c_str());
   fprintf(fp, "D LOGSIZE %d\n", _cfgFile.logMgrParam.logSize);
   fprintf(fp, "D LOGLEVEL %s\n", Logger::_severity[_cfgFile.logMgrParam.logLevel]);

   map<string, LogCfgComponentParam>::iterator compIt;

   for(compIt = _cfgFile.components.begin(); 
       compIt != _cfgFile.components.end(); compIt++)
   {
      const string &comp = compIt->first;
      LogCfgComponentParam &compParam = compIt->second;

      if(compParam.loglevel != _logParam.logLevel)
      {
         fprintf(fp, "C %s LOGLEVEL %s\n", comp.c_str(), 
                 Logger::_severity[compParam.loglevel]);
      }

      map<string, LogCompFileParam>::iterator fileIt;

      for(fileIt = compParam.fileDet.begin(); fileIt != compParam.fileDet.end();
          fileIt++)
      {
         const string &file = fileIt->first;
         vector<SourceFileRange> &ranges = fileIt->second.lineRanges;

         for(unsigned int idx = 0; idx < ranges.size() && idx < MAX_RANGE_FILE; idx++)
         {
            fprintf(fp, "F %s %s %d %d\n", file.c_str(), comp.c_str(),
                    ranges[idx].from, ranges[idx].to);
         }
      }
   }

   fflush(fp);
   fclose(fp);
}

void LogMgr::_loadConfigFile()
{
   char separator[] = " \t\n\r";
   char *word;
   char *brkt;
   char message[1100];
   char currline[1001];

   currline[1000] = '\0';

   FILE *fp = fopen(_logConfigFilename.c_str(), "r");

   if(fp == NULL)
   {
      pthread_mutex_unlock(&_fileMutex);
      raiseAlarm("Unable to read config file", NULL, -2);
      pthread_mutex_lock(&_fileMutex);

      return;
   }

   int ret = 0;
   int linenumber = 0;

   while(!feof(fp))
   {
      linenumber++;
      if(fgets(currline, 1000, fp) == NULL)
      {
         break;
      }

      if(strlen(currline) > 900)
      {
         sprintf(message, "Line too long. Line number [%d]", linenumber);
         ret = -1;
         break;
      }

      word = strtok_r(currline, separator, &brkt);
      if(word == NULL || word[0] == '#')
      {
         continue;
      }

      char *command = word;

      if(strcmp(command, "C") == 0)
      {
         char *component = strtok_r(NULL, separator, &brkt);
         if(component == NULL)
         {
            sprintf(message, "Component for command [%s] not defined. lineno "
                             "[%d]", command, linenumber);
            ret = -1;
            break;
         }

         char *param = strtok_r(NULL, separator, &brkt);
         if(param == NULL)
         {
            sprintf(message, "No Parameter for component[%s] specified. lineno "
                             "[%d]", component, linenumber);
            ret = -1;
            break;
         }

         if(strcmp(param, "LOGLEVEL") == 0)
         {
            char *level = strtok_r(NULL, separator, &brkt);
            if(level == NULL)
            {
               sprintf(message, "Level for Component [%s] not defined. lineno "
                                "[%d]", component, linenumber);
               ret = -1;
               break;
            }
   
            char *extra = strtok_r(NULL, separator, &brkt);
            if(extra != NULL)
            {
               sprintf(message, "Additional data [%s] there for component [%s]."
                                " Lineno [%d]", extra, component, linenumber);
               ret = -1;
               break;
            }

            ret = -1;

            for(int idx = 0; idx < 5; idx++)
            {
               if(strcmp(level, Logger::_severity[idx]) == 0)
               {
                  _cfgFile.components[component].loglevel = (Logger::LogLevel)idx;
                  ret = 0;
                  break;
               }
            }

            if(ret == -1)
            {
               sprintf(message, "Unknown level [%s] for component [%s] "
                                " Lineno [%d]", level, component, linenumber);
               break;
            }
         }
         else
         {
            sprintf(message, "Unknown param [%s] for component [%s] "
                             "lineno [%d]", param, component, linenumber);
            ret = -1;
            break;
         }
      }
      else if(strcmp(command, "F") == 0)
      {
         char *fname = strtok_r(NULL, separator, &brkt);
         if(fname == NULL)
         {
            sprintf(message, "No filename defined for command [%s]. Lineno "
                             "[%d]", command, linenumber);
            ret = -1;
            break;
         }

         char *comp = strtok_r(NULL, separator, &brkt);
         if(comp == NULL)
         {
            sprintf(message, "No component for file [%s]. Lineno [%d]",
                    fname, linenumber);
            ret = -1;
            break;
         }

         char *fnum = strtok_r(NULL, separator, &brkt);
         if(fnum == NULL)
         {
            sprintf(message, "No line number range defined for file [%s]. "
                             "Lineno [%d]", fname, linenumber);
            ret = -1;
            break;
         }

         char *tnum = strtok_r(NULL, separator, &brkt);
         if(tnum == NULL)
         {
            sprintf(message, "No line number range defined for file [%s]. "
                             "Lineno [%d]", fname, linenumber);
            ret = -1;
            break;
         }

         char *extra = strtok_r(NULL, separator, &brkt);

         if(extra != NULL)
         {
            sprintf(message, "Extra data[%s] is defined for file [%s]. Lineno "
                             "[%d]", extra, linenumber);
            ret = -1;
            break;
         }

         int fn, tn;
         if((sscanf(fnum, "%d", &fn) != 1) ||
            (sscanf(tnum, "%d", &tn) != 1))
         {
            sprintf(message, "Number conversion error for file [%s] from [%s] "
                           "to [%s]. lineno[%d]", fname, fnum, tnum,
                           linenumber);
            ret = -1;
            break;
         }

         if(fn > tn)
         {
            sprintf(message, "Range [%d - %d] is not proper for file [%s]. "
                           "Lineno [%d]", fn, tn, fname, linenumber);
            ret = -1;
            break;
         }

         if(_cfgFile.components.find(comp) == _cfgFile.components.end())
         {
            _cfgFile.components[comp].loglevel = Logger::ALWAYS;
         }

         SourceFileRange lrange;
         lrange.from = fn;
         lrange.to = tn;
         _cfgFile.components[comp].fileDet[fname].lineRanges.push_back(lrange);
      }
      else if(strcmp(command, "D") == 0)
      {
         char *attr = strtok_r(NULL, separator, &brkt);

         if(attr == NULL)
         {
            sprintf(message, "No Attribute specified. Lineno[%d]", linenumber);
            ret = -1;
            break;
         }

         char *value = strtok_r(NULL, separator, &brkt);

         if(value == NULL)
         {
            sprintf(message, "No value specified for Attribure [%s]. "
                             "Lineno[%d]", attr, linenumber);
            ret = -1;
            break;
         }

         char *extra = strtok_r(NULL, separator, &brkt);

         if(extra != NULL)
         {
            sprintf(message, "Extra characters [%s] found. Lineno[%d]",
                    extra, linenumber);
            ret = -1;
            break;
         }

         if(strcmp(attr, "LOGFILE") == 0)
         {
            _cfgFile.logMgrParam.logFile = value;
         }
         else if(strcmp(attr, "LOGDIR") == 0)
         {
            _cfgFile.logMgrParam.logDir = value;

            if(value[strlen(value) - 1] != '/')
            {
               _cfgFile.logMgrParam.logDir += "/";
            }
         }
         else if(strcmp(attr, "LOGSIZE") == 0)
         {
            if(sscanf(value, "%d", &_cfgFile.logMgrParam.logSize) != 1)
            {
               sprintf(message, "Number conversion error for logsize [%s]. "
                                "Lineno[%d]", value, linenumber);
               ret = -1;
               break;
            }
         }
         else if(strcmp(attr, "LOGLEVEL") == 0)
         {
            ret = -1;

            for(int idx = 0; idx < 5; idx++)
            {
               if(strcmp(value, Logger::_severity[idx]) == 0)
               {
                  _cfgFile.logMgrParam.logLevel = (Logger::LogLevel)idx;
                  ret = 0;
                  break;
               }
            }

            if(ret == -1)
            {
               sprintf(message, "Unknown loglevel [%s] Lineno [%d]", 
                       value, linenumber);
               break;
            }
         }
      }
      else
      {
         sprintf(message, "Unknown command [%s] lineno [%d]", command, 
                 linenumber);
         ret = -1;
         break;
      }
   }

   if(ret == -1)
   {
      pthread_mutex_unlock(&_fileMutex);
      raiseAlarm(message, NULL, -2);
      pthread_mutex_lock(&_fileMutex);
   }

   map<string, LogCfgComponentParam>::iterator compIt;

   for(compIt = _cfgFile.components.begin(); 
       compIt != _cfgFile.components.end(); compIt++)
   {
      if(compIt->second.loglevel == Logger::ALWAYS)
      {
         compIt->second.loglevel = _cfgFile.logMgrParam.logLevel;
      }
   }

   fclose(fp);
}
