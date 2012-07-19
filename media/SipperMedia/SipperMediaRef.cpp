#include "SipperMediaRef.h"

SipperMediaRef::SipperMediaRef()
{
   pthread_mutex_init(&_mutex, NULL);
   _count = 1;
}

SipperMediaRef::~SipperMediaRef()
{
   pthread_mutex_destroy(&_mutex);
}

void SipperMediaRef::addRef()
{
   pthread_mutex_lock(&_mutex);
   _count++;
   pthread_mutex_unlock(&_mutex);
}

unsigned int SipperMediaRef::removeRef()
{
   pthread_mutex_lock(&_mutex);
   _count--;
   unsigned int locCount = _count;
   pthread_mutex_unlock(&_mutex);

   if(locCount == 0)
   {
      delete this;
   }

   return locCount;
}

SipperMediaRefObjHolder::SipperMediaRefObjHolder(SipperMediaRef *obj)
{
   _obj = obj;
}

SipperMediaRefObjHolder::SipperMediaRefObjHolder()
{
   _obj = NULL;
}

SipperMediaRefObjHolder::~SipperMediaRefObjHolder()
{
   if(_obj != NULL)
   {
      _obj->removeRef();
   }
}

SipperMediaRef * SipperMediaRefObjHolder::getObj()
{
   return _obj;
}

void SipperMediaRefObjHolder::setObj(SipperMediaRef *inObj)
{
   if(_obj != NULL)
   {
      _obj->removeRef();
   }

   _obj = inObj;
}
