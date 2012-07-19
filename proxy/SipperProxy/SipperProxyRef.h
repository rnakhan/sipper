#ifndef __SIPPER_PROXY_REF_H__
#define __SIPPER_PROXY_REF_H__

#include <pthread.h>

class SipperProxyRef
{
   protected:

      pthread_mutex_t _mutex;
      unsigned int _count;

   protected:

      SipperProxyRef();
      virtual ~SipperProxyRef();

   public:

      void addRef();
      virtual unsigned int removeRef();

   private:

      SipperProxyRef(const SipperProxyRef &);
      SipperProxyRef & operator = (const SipperProxyRef &);
};

template <class _MSG>
class SipperProxyRefObjHolder
{
   private:

      _MSG *_obj;

   public:

      SipperProxyRefObjHolder(_MSG *inMsg) :
         _obj(inMsg)
      {
      }

      ~SipperProxyRefObjHolder()
      {
         if(_obj != NULL) _obj->removeRef();
      }

      _MSG * getObj()
      {
         return _obj;
      }

      void setObj(_MSG *inObj)
      {
         if(inObj == _obj) return;

         if(_obj != NULL) _obj->removeRef();

         _obj = inObj;
      }

   private:

      SipperProxyRefObjHolder(SipperProxyRefObjHolder &);
      SipperProxyRefObjHolder & operator = (const SipperProxyRefObjHolder &);
};

#endif
