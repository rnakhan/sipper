#include "SipperProxyLogger.h"
LOG("SipperProxyConfig");
#include "SipperProxyConfig.h"

SipperProxyConfig * SipperProxyConfig::_instance = NULL;


SipperProxyConfig & SipperProxyConfig::getInstance()
{
   if(_instance == NULL)
   {
      _instance = new SipperProxyConfig();
   }

   return *_instance;
}

SipperProxyConfig::SipperProxyConfig()
{

}

void SipperProxyConfig::loadConfigFile(const std::string &configFile)
{
   MutexGuard(&_mutex);

   FILE *fp = fopen(configFile.c_str(), "r");

   if(fp == NULL)
   {
      return;
   }

   std::string section = "Global";

   char data[201]; data[200] = '\0';
   while(fgets(data, 200, fp) != NULL)
   {
      int len = strlen(data);

      while((len > 0) && ((data[len - 1] == '\r') || (data[len - 1] == '\n')))
      {
         len--;
         data[len] = '\0';
      }
      
      if(data[0] == '#')
      {
         continue;
      }

      if(data[0] == '[')
      {
         char *start = data + 1;
         while((*start != '\0') && (*start == ' '))
         {
            start++;
         }

         if(*start == '\0') continue;

         char *end = strstr(data + 1, "]");
         if(end == NULL)
         {
            continue;
         }

         *end = '\0';
         end--;
         while((end > start) && (*end == ' '))
         {
            *end = '\0';
            end--;
         }

         if(end == start) continue;
         section = start;

         logger.logMsg(TRACE_FLAG, 0, 
                       "Section [%s]\n", section.c_str());

         continue;
      }

      char *paramName = data;
      while(*paramName == ' ') paramName++;

      char *end = strstr(paramName, "=");
      if(end == NULL) continue;
      char *paramValue = end + 1;

      *end = '\0'; end--;
      while((end > paramName) && (*end == ' '))
      {
         *end = '\0';
         end--;
      }

      if(*paramName == '\0') continue;

      while(*paramValue == ' ') paramValue++;
      end = paramValue;

      while(*end != '\0' && *end != ' ')
      {
         end++;
      }

      if(*end == ' ') *end = '\0';
      _sectionConfig[section][paramName] = paramValue;

      logger.logMsg(ALWAYS_FLAG, 0, 
                    "Section[%s] Name[%s] Value[%s]\n", 
                    section.c_str(), paramName, paramValue);
   }

   fclose(fp);
}

std::string SipperProxyConfig::getConfig(const std::string &section, 
                               const std::string &paramName, 
                               const std::string &defaultValue)
{
   std::string ret;

   {
      MutexGuard(&_mutex);

      SectionMapIt it;
      if(section == "")
      {
         it = _sectionConfig.find("Global");
      }
      else
      {
         it = _sectionConfig.find(section);
      }

      if(it == _sectionConfig.end())
      {
         ret = defaultValue;
      }
      else
      {
         ConfigMap &currconfig = it->second;
         ConfigMapIt cit = currconfig.find(paramName);

         if(cit == currconfig.end())
         {
            ret = defaultValue;
         }
         else
         {
            ret = cit->second;
         }
      }
   }

   return ret;
}
