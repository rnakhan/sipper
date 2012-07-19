#include "SipperMediaLogger.h"
LOG("SipperMediaPortMgr");
#include "SipperMediaPortMgr.h"
#include "SipperMediaConfig.h"
#include <algorithm>

SipperMediaPortMgr * SipperMediaPortMgr::_instance = NULL;


SipperMediaPortMgr & SipperMediaPortMgr::getInstance()
{
   if(_instance == NULL)
   {
      _instance = new SipperMediaPortMgr();
   }

   return *_instance;
}

SipperMediaPortMgr::SipperMediaPortMgr()
{
   SipperMediaConfig &config = SipperMediaConfig::getInstance();

   unsigned short lowport  = atoi(config.getConfig("Global", "MinRtpPort", "16000").c_str());
   unsigned short highport = atoi(config.getConfig("Global", "MaxRtpPort", "19000").c_str());

   addPorts(lowport, highport);
}

void SipperMediaPortMgr::_getPortSet(unsigned short startPort, 
                                     unsigned short endPort, 
                                     SipperMediaPortSet &result)
{
   result.clear();

   //startPort should be even. EndPort is odd.
   if(startPort & 0x1) startPort++; 
   if(!(endPort & 0x1)) endPort--;

   for(unsigned short idx = startPort; idx < endPort; idx++, idx++)
   {
      result.insert(idx);
   }

   return;
}

void SipperMediaPortMgr::_getPortRange(unsigned int tabCount, const SipperMediaPortSet &data,
                                    std::string &result) const
{
   if(data.size() == 0)
   {
      return;
   }

   if(tabCount > 19)
   {
      tabCount = 19;
   }

   char tabs[20];

   for(unsigned int idx = 0; idx < tabCount; idx++)
   {
      tabs[idx] = '\t';
   }

   tabs[tabCount] = '\0';

   char rangeStr[100];

   SipperMediaPortSetCIt it = data.begin();
   int first = *it; ++it;
   int last = first;

   for(;it != data.end(); ++it)
   {
      int curr = *it;
      if(curr != last + 2)
      {
         sprintf(rangeStr, "%s<Range Start=\"%d\" End=\"%d\" />\n", 
                 tabs, first, last + 1);
         result += rangeStr;
         first = curr;
      }

      last = curr;
   }

   sprintf(rangeStr, "%s<Range Start=\"%d\" End=\"%d\" />\n", 
           tabs, first, last + 1);
   result += rangeStr;
   return;
}

void SipperMediaPortMgr::addPorts(unsigned short startPort, unsigned short endPort)
{
   MutexGuard(&_mutex);

   SipperMediaPortSet inputPorts;
   _getPortSet(startPort, endPort, inputPorts);

   _configuredPorts.insert(inputPorts.begin(), inputPorts.end());

   SipperMediaPortSet notInUsePorts;
   std::set_difference(inputPorts.begin(), inputPorts.end(),
                       _inusePorts.begin(), _inusePorts.end(),
                       std::inserter(notInUsePorts, notInUsePorts.begin()));

   std::set_difference(notInUsePorts.begin(), notInUsePorts.end(),
                       _usedPorts.begin(), _usedPorts.end(),
                       std::inserter(_freePorts, _freePorts.begin()));
}

void SipperMediaPortMgr::removePorts(unsigned short startPort, 
                                  unsigned short endPort)
{
   MutexGuard(&_mutex);

   if(startPort & 0x1) startPort++; 
   if(!(endPort & 0x1)) endPort--;
   if(startPort > endPort) return;

   _configuredPorts.erase(_configuredPorts.lower_bound(startPort),
                          _configuredPorts.lower_bound(endPort));
   _freePorts.erase(_freePorts.lower_bound(startPort),
                    _freePorts.lower_bound(endPort));
   _usedPorts.erase(_usedPorts.lower_bound(startPort),
                    _usedPorts.lower_bound(endPort));
}

int SipperMediaPortMgr::getPort(unsigned short &port)
{
   MutexGuard(&_mutex);

   port = 0;

   if(_freePorts.size() == 0)
   {
      _freePorts.insert(_usedPorts.begin(), _usedPorts.end());
      _usedPorts.clear();
   }

   SipperMediaPortSetIt it = _freePorts.begin();

   if(it == _freePorts.end())
   {
      return -1;
   }

   port = (*it);
   _freePorts.erase(it);
   _inusePorts.insert(port);

   return 0;
}

void SipperMediaPortMgr::releasePort(unsigned short port)
{
   {
   MutexGuard(&_mutex);

   if(port & 0x1) 
   {
      //Port is not even
      logger.logMsg(ERROR_FLAG, 0, "Port[%d] is not even.\n", port);
      return;
   }

   if(_configuredPorts.find(port) == _configuredPorts.end())
   {
      return;
   }

   _usedPorts.insert(port);
   _inusePorts.erase(port);
   }

   logger.logMsg(ALWAYS_FLAG, 0, "PortInfo.\n%s\n", toLog(1).c_str());
}

void SipperMediaPortMgr::getPortReport(int command, std::string &result)
{
   MutexGuard(&_mutex);

   switch(command)
   {
      case 0: 
      {
         result += "Configured:\n";
         _getPortRange(1, _configuredPorts, result);
         result += "FreePorts:\n";
         _getPortRange(1, _freePorts, result);
         result += "UsedFreePorts:\n";
         _getPortRange(1, _usedPorts, result);
         result += "InUse:\n";
         _getPortRange(1, _inusePorts, result);
      }
      break;

      case 1:
      {
         result += "InUse:\n";
         _getPortRange(1, _inusePorts, result);
      }
      break;

      case 2:
      {
         result += "Configured:\n";
         _getPortRange(1, _configuredPorts, result);
      }
      break;

      case 3:
      {
         result += "FreePorts:\n";
         _getPortRange(1, _freePorts, result);
         result += "UsedFreePorts:\n";
         _getPortRange(1, _usedPorts, result);
      }
      break;
   }

   return;
}

std::string SipperMediaPortMgr::toLog(unsigned int tabCount) const
{
   MutexGuard(&_mutex);
   if(tabCount > 19)
   {
      tabCount = 19;
   }

   char tabs[20];

   for(unsigned int idx = 0; idx < tabCount; idx++)
   {
      tabs[idx] = '\t';
   }

   tabs[tabCount] = '\0';

   std::string ret;
   ret += tabs; ret += "<SipperMediaPortMgr>\n";
   ret += tabs; ret += "\t<Configured>\n";
   _getPortRange(tabCount + 2, _configuredPorts, ret);
   ret += tabs; ret += "\t</Configured>\n";
   ret += tabs; ret += "\t<FreePorts>\n";
   _getPortRange(tabCount + 2, _freePorts, ret);
   ret += tabs; ret += "\t</FreePorts>\n";
   ret += tabs; ret += "\t<UsedFreePorts>\n";
   _getPortRange(tabCount + 2, _usedPorts, ret);
   ret += tabs; ret += "\t</UsedFreePorts>\n";
   ret += tabs; ret += "\t<InUse>\n";
   _getPortRange(tabCount + 2, _inusePorts, ret);
   ret += tabs; ret += "\t</InUse>\n";
   ret += tabs; ret += "</SipperMediaPortMgr>\n";
   return ret;
}
