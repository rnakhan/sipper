#ifndef __SIPPER_MEDIA_REF_H__
#define __SIPPER_MEDIA_REF_H__

#include <pthread.h>

class SipperMediaRef
{
   protected:

      pthread_mutex_t _mutex;
      unsigned int _count;

   protected:

      SipperMediaRef();
      virtual ~SipperMediaRef();

   public:

      void addRef();
      virtual unsigned int removeRef();

   private:

      SipperMediaRef(const SipperMediaRef &);
      SipperMediaRef & operator = (const SipperMediaRef &);
};

class SipperMediaRefObjHolder
{
   private:

      SipperMediaRef *_obj;

   public:

      SipperMediaRefObjHolder(SipperMediaRef *);
      SipperMediaRefObjHolder();
      ~SipperMediaRefObjHolder();

      SipperMediaRef * getObj();
      void setObj(SipperMediaRef *inObj);

   private:

      SipperMediaRefObjHolder(SipperMediaRefObjHolder &);
      SipperMediaRefObjHolder & operator = (const SipperMediaRefObjHolder &);
};

#endif
