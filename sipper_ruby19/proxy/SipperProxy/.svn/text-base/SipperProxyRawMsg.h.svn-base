#ifndef __SIPPER_PROXY_RAW_MSG_H__
#define __SIPPER_PROXY_RAW_MSG_H__

#include "SipperProxyRef.h"
#include "SipperProxyMsgFactory.h"

#define SMSG_RECLEN_OFF        0
#define SMSG_DIREC_OFF         4
#define SMSG_MSGTYPE_OFF       5
#define SMSG_NAME_LEN_OFF      6
#define SMSG_BRN_LEN_OFF       7
#define SMSG_CALL_LEN_OFF      9
#define SMSG_MSG_LEN_OFF      11
#define SMSG_IP_OFF           13
#define SMSG_PORT_OFF         17
#define SMSG_TIME_SEC_OFF     19
#define SMSG_TIME_USEC_OFF    23
#define SMSG_RESP_REQ_LEN_OFF 27
#define SMSG_DYN_PART_OFF     28

#define SET_SHORT_TO_BUF(VAR, OFF) \
{ \
   unsigned short temp = htons(VAR); \
   memcpy(outBuf + OFF, &temp, 2); \
}

#define SET_INT_TO_BUF(VAR, OFF) \
{ \
   unsigned int temp = htonl(VAR); \
   memcpy(outBuf + OFF, &temp, 4); \
}

#define SET_RAW_TO_BUF(VAR, LEN, OFF) \
{ \
   memcpy(outBuf + OFF, (void *)VAR, LEN); \
}

class SipperProxyRawMsg : virtual public SipperProxyRef
{
   private:

      char _defaultMem[SIPPER_PROXY_DEF_MSGLEN];

      char *_defaultBuffer;
      unsigned int _defaultMemLen;
      char *_allocBuffer;
      
   private:

      char *_buffer;
      unsigned int _bufLen;

   protected:

      SipperProxyRawMsg();
      ~SipperProxyRawMsg();

      void _releaseBuf();

   public:

      static SipperProxyRawMsg * getFactoryMsg();
      static void setFactoryLen(unsigned int factoryLen);
      static void closeFactory();

      char * getBuf(unsigned int &len)
      {
         len = _bufLen;
         return _buffer;
      }

      unsigned int getLen() const
      {
         return _bufLen;
      }

      void setData(const char *inBuf, unsigned int inBufLen);
      void setLen(unsigned int inBufLen);
      void reset()
      {
         _releaseBuf();
      }

      virtual unsigned int removeRef();

   public:

      friend class SipperProxyMsgFactory<SipperProxyRawMsg>;

   private:

      bool _facObj;

      static SipperProxyMsgFactory<SipperProxyRawMsg> _factory;

   public:

      static std::string toLog(unsigned int tabCount)
      {
         _factory.setName("SipperProxyRawMsg");
         return _factory.toLog(tabCount);
      }
};

#endif
