#ifndef __SIPPER_PROXY_LOCK_H__
#define __SIPPER_PROXY_LOCK_H__

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <sys/time.h>
#endif

#include <pthread.h>
#include "SipperProxyPortable.h"

class SipperProxyMutex
{
   public:

      enum MutexType
      {
         NORMAL,
         RECURSIVE
      };

   private:

      mutable pthread_mutex_t _mutex;
      mutable pthread_cond_t _cond;

      pthread_mutexattr_t _attr;
      MutexType _type;

   private:

      void _initType(MutexType type)
      {
         _type = NORMAL;
         pthread_mutexattr_init(&_attr);

         switch(_type)
         {
            case RECURSIVE:
            {
               pthread_mutexattr_settype(&_attr, PTHREAD_MUTEX_RECURSIVE);
            }
            break;

            default:
            {
               pthread_mutexattr_settype(&_attr, PTHREAD_MUTEX_NORMAL);
            }
         }

         pthread_mutex_init(&_mutex, &_attr);
         pthread_cond_init(&_cond, NULL);
      }
   public:

      SipperProxyMutex(MutexType type) 
      {
         _initType(type);
      }

      SipperProxyMutex()
      {
         _initType(NORMAL);
      }

      ~SipperProxyMutex()
      {
         pthread_cond_destroy(&_cond);
         pthread_mutex_destroy(&_mutex);
         pthread_mutexattr_destroy(&_attr);
      }

      pthread_mutex_t * getMutex() const
      {
         return &_mutex;
      }

      pthread_cond_t * getCond() const
      {
         return &_cond;
      }

      void lock() const
      {
         pthread_mutex_lock(&_mutex);
      }

      void unlock() const
      {
         pthread_mutex_unlock(&_mutex);
      }
};

class SipperProxyLock
{
   private:

      const SipperProxyMutex *_mutex;

   public:

      SipperProxyLock(const SipperProxyMutex *mutex) :
         _mutex(mutex)
      {
         if(_mutex)
         {
            _mutex->lock();
         }
      }

      ~SipperProxyLock()
      {
         if(_mutex)
         {
            _mutex->unlock();
         }
      }

      void wait(int timeout)
      {
         if(_mutex)
         {
            if(timeout == 0)
            {
               pthread_cond_wait(_mutex->getCond(), _mutex->getMutex());
            }
            else
            {
               struct timeval currTime;
               SipperProxyPortable::getTimeOfDay(&currTime);              

               struct timespec WaitTime;
               WaitTime.tv_sec = currTime.tv_sec;
               WaitTime.tv_nsec = (currTime.tv_usec * 1000);

               WaitTime.tv_sec += (timeout / 1000);
               long millisec = timeout % 1000;
               WaitTime.tv_nsec += (millisec * 1000000);

               if(WaitTime.tv_nsec >= 1000000000L)
               {
                  WaitTime.tv_nsec -= 1000000000L;
                  WaitTime.tv_sec++;
               }

               pthread_cond_timedwait(_mutex->getCond(), _mutex->getMutex(), 
                                      &WaitTime);
            }
         }
      }

      void signal()
      {
         if(_mutex)
         {
            pthread_cond_signal(_mutex->getCond());
         }
      }
};

#define MutexGuard(X) SipperProxyLock __locLock(X)
#define MutexWait(X) __locLock.wait(X)
#define MutexSignal() __locLock.signal()

#endif
