#ifndef __SIPPER_MEDIA_FILE_LOADER_H__
#define __SIPPER_MEDIA_FILE_LOADER_H__

#pragma warning(disable: 4786)

#include "SipperMediaRef.h"

#include <string>
#include <map>
#include <pthread.h>

#include <sys/types.h> 
#include <sys/stat.h>

class SipperMediaFileContent : public SipperMediaRef
{
   public:

#ifndef __UNIX__
      struct _stat filestat;
#else
      struct stat filestat;
#endif

      std::string filename;
      unsigned char *data;
      int  len;

   public:

      SipperMediaFileContent()
      {
         data = NULL;
         len = 0;
      }

      ~SipperMediaFileContent()
      {
         if(data != NULL) delete []data;
         data = NULL;
      }
};

typedef std::map<std::string, SipperMediaFileContent *> SipperFileContentMap;
typedef SipperFileContentMap::iterator SipperFileContentMapIt;

class SipperMediaFileLoader
{
private:

   static SipperMediaFileLoader *_instance;

   SipperFileContentMap _contentMap;
   pthread_mutex_t _mutex;

   SipperMediaRefObjHolder _emptyFileHolder;

public:

   static SipperMediaFileLoader & getInstance()
   {
      if(_instance == NULL)
      {
         _instance = new SipperMediaFileLoader();
      }

      return *_instance;
   }

   SipperMediaFileLoader();
   SipperMediaFileContent * loadFile(const std::string &filename);

private:

   void _loadData(const std::string &filename);
};

#endif
