#ifndef __SIPPER_MEDIA_PORT_MGR_H__
#define __SIPPER_MEDIA_PORT_MGR_H__

#include "SipperMediaLock.h"

#include <map>
#include <set>

typedef std::set<unsigned short> SipperMediaPortSet;
typedef SipperMediaPortSet::iterator SipperMediaPortSetIt;
typedef SipperMediaPortSet::const_iterator SipperMediaPortSetCIt;

class SipperMediaPortMgr 
{
   private:

      static SipperMediaPortMgr *_instance;

      SipperMediaMutex _mutex;

      SipperMediaPortSet _configuredPorts;
      SipperMediaPortSet _inusePorts;
      SipperMediaPortSet _freePorts;
      SipperMediaPortSet _usedPorts;

   private:

      SipperMediaPortMgr();

   private:

      void _getPortSet(unsigned short startPort, unsigned short endPort,
                       SipperMediaPortSet &result);
      void _getPortRange(unsigned int tabCount, const SipperMediaPortSet &data, 
                         std::string &result) const;

   public:

      static SipperMediaPortMgr & getInstance();

      void addPorts(unsigned short startPort, unsigned short endPort);
      void removePorts(unsigned short startPort, unsigned short endPort);
      void getPortReport(int command, std::string &result);

      int getPort(unsigned short &outport);
      void releasePort(unsigned short port);

      std::string toLog(unsigned int tabCount) const;
};

#endif
