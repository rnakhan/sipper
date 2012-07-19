#ifndef __SIPPER_PROXY_CONFIG_H__
#define __SIPPER_PROXY_CONFIG_H__

#pragma warning(disable: 4786)
#pragma warning(disable: 4503)

#include <string>
#include <map>
#include "SipperProxyLock.h"

typedef std::map<std::string, std::string> ConfigMap;
typedef ConfigMap::iterator ConfigMapIt;
typedef std::map<std::string, ConfigMap> SectionMap;
typedef SectionMap::iterator SectionMapIt;

class SipperProxyConfig
{
private:

   static SipperProxyConfig *_instance;

   SipperProxyMutex _mutex;
   SectionMap _sectionConfig;

private:

   SipperProxyConfig();

public:

   static SipperProxyConfig & getInstance();
   void loadConfigFile(const std::string &configFile);
   std::string getConfig(const std::string &section, const std::string &paramName, const std::string &defaultValue = "");
};

#endif
