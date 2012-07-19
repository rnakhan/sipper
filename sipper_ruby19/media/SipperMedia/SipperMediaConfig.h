#ifndef __SIPPER_MEDIA_CONFIG_H__
#define __SIPPER_MEDIA_CONFIG_H__

#pragma warning(disable: 4786)
#pragma warning(disable: 4503)

#include <string>
#include <map>
#include "SipperMediaLock.h"

typedef std::map<std::string, std::string> ConfigMap;
typedef ConfigMap::iterator ConfigMapIt;
typedef std::map<std::string, ConfigMap> SectionMap;
typedef SectionMap::iterator SectionMapIt;

class SipperMediaConfig
{
private:

   static SipperMediaConfig *_instance;

   SipperMediaMutex _mutex;
   SectionMap _sectionConfig;

private:

   SipperMediaConfig();

public:

   static SipperMediaConfig & getInstance();
   void loadConfigFile(const std::string &configFile);
   std::string getConfig(const std::string &section, const std::string &paramName, const std::string &defaultValue = "");
};

#endif
