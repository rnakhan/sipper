#include "SipperProxyRawMsg.h"

SipperProxyMsgFactory<SipperProxyRawMsg> SipperProxyRawMsg::_factory = SipperProxyMsgFactory<SipperProxyRawMsg>(SIPPER_PROXY_PRELOAD_MSG);

SipperProxyRawMsg::SipperProxyRawMsg() :
   _allocBuffer(NULL),
   _buffer(NULL),
   _bufLen(0),
   _facObj(false)
{
   _defaultBuffer = _defaultMem;
   _defaultMemLen = SIPPER_PROXY_DEF_MSGLEN;

   _buffer = _defaultBuffer;
   _bufLen = _defaultMemLen;
}

SipperProxyRawMsg::~SipperProxyRawMsg()
{
   _releaseBuf();
}

void SipperProxyRawMsg::_releaseBuf()
{
   if(_allocBuffer)
   {
      delete []_allocBuffer;
      _allocBuffer = NULL;
   }

   _buffer = _defaultBuffer;
   _bufLen = 0;
}

void SipperProxyRawMsg::setData(const char *inBuf, unsigned int inBufLen)
{
   _releaseBuf();

   if(inBufLen > _defaultMemLen)
   {
      _allocBuffer = new char[inBufLen];
      _buffer = _allocBuffer;
   }

   memcpy(_buffer, inBuf, inBufLen);
   _bufLen = inBufLen;
}

void SipperProxyRawMsg::setLen(unsigned int inBufLen)
{
   _releaseBuf();

   if(inBufLen > _defaultMemLen)
   {
      _allocBuffer = new char[inBufLen];
      _buffer = _allocBuffer;
   }

   _bufLen = inBufLen;
}

SipperProxyRawMsg * SipperProxyRawMsg::getFactoryMsg()
{
   return _factory.getMsg();
}

void SipperProxyRawMsg::setFactoryLen(unsigned int factoryLen)
{
   _factory.setLen(factoryLen);
}

void SipperProxyRawMsg::closeFactory()
{
   _factory.close();
}

unsigned int SipperProxyRawMsg::removeRef()
{
   unsigned int ret = SipperProxyRef::removeRef();

   if(ret == 1)
   {
      _factory.putMsg(this);
   }

   return ret;
}

