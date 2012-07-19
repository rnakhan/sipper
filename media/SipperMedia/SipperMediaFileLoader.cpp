#include "SipperMediaLogger.h"
LOG("SipperMediaFileLoader");

#include "SipperMediaFileLoader.h"

#ifndef __UNIX__
#include <winsock2.h>
#else
#include <netinet/in.h>
#endif

SipperMediaFileLoader * SipperMediaFileLoader::_instance = NULL;

SipperMediaFileLoader::SipperMediaFileLoader()
{
   pthread_mutex_init(&_mutex, NULL);

   _emptyFileHolder.setObj(new SipperMediaFileContent());
   SipperMediaFileContent *currobj = dynamic_cast<SipperMediaFileContent *>(_emptyFileHolder.getObj());

   currobj->data = new unsigned char[4000];
   currobj->len = 4000;
   memset(currobj->data, 0xFF, 4000);
}

void SipperMediaFileLoader::_loadData(const std::string &filename)
{
   SipperFileContentMapIt it = _contentMap.find(filename);

   if(it != _contentMap.end())
   {
      it->second->removeRef();
      _contentMap.erase(it);
   }

   FILE *fp = fopen(filename.c_str(), "r");

   if(fp != NULL)
   {
      int data[6];

      for(int idx = 0; idx < 6; idx++) data[idx] = 0;
      
      if(fread(data, 4, 6, fp) == 6)
      {
         for(int idx = 0; idx < 6; idx++) data[idx] = ntohl(data[idx]);

         logger.logMsg(ALWAYS_FLAG, 0, 
                       "File[%s] Header: Magic[%x] Offset[%d] Size[%d] "
                       "Encoding[%d] Sample[%d] Channels[%d]\n",
                       filename.c_str(), data[0], data[1], data[2], 
                       data[3], data[4], data[5]);

         if((data[0] == 0x2e736e64) && (data[3] == 1) && (data[4] == 8000) && (data[5] == 1))
         {
            SipperMediaRefObjHolder holder(new SipperMediaFileContent());
            SipperMediaFileContent *newInfo = 
                     dynamic_cast<SipperMediaFileContent *>(holder.getObj());

            newInfo->filename = filename;
#ifndef __UNIX__
			_stat(filename.c_str(), &newInfo->filestat );
#else
            stat(filename.c_str(), &newInfo->filestat);
#endif
            fseek(fp, data[1], SEEK_SET);

            if(data[2] != 0xFFFFFFFF)
            {
               newInfo->data = new unsigned char[4000];
               newInfo->len = 0;

               while(true)
               {
                  int len = fread(newInfo->data + newInfo->len, 1, 4000, fp);
                  newInfo->len += len;

                  if(len < 4000)
                  {
                     break;
                  }
                  
                  unsigned char *tmp = new unsigned char[newInfo->len + 4000];
                  memcpy(tmp, newInfo->data, newInfo->len);

                  delete []newInfo->data;
                  newInfo->data = tmp;
               }
            }
            else
            {
               newInfo->data = new unsigned char[data[2] ];
               newInfo->len = 0;
               newInfo->len = fread(newInfo->data, 1, data[2], fp);
            }

            logger.logMsg(ALWAYS_FLAG, 0, 
                          "Loading File[%s] Len[%d] to cache.\n", 
                          filename.c_str(), newInfo->len);

            newInfo->addRef();
            _contentMap[filename] = newInfo;
         }
         else
         {
            logger.logMsg(ERROR_FLAG, 0, 
                          "Not an expected file. [%s]\n", filename.c_str());
         }
      }
      else
      {
         logger.logMsg(ERROR_FLAG, 0, 
                       "Couldn't read header of [%s].\n", filename.c_str());
      }

      fclose(fp);
   }
   else
   {
      logger.logMsg(ERROR_FLAG, 0, 
                    "Error opening file [%s].\n", filename.c_str());
   }
}

SipperMediaFileContent * SipperMediaFileLoader::loadFile(const std::string &filename)
{
   SipperMediaFileContent *result = dynamic_cast<SipperMediaFileContent *>(_emptyFileHolder.getObj());

   pthread_mutex_lock(&_mutex);

   SipperFileContentMapIt it = _contentMap.find(filename);

   if(it != _contentMap.end())
   {
      SipperMediaFileContent *stored = it->second;

#ifndef __UNIX__
      struct _stat currstat;
	  _stat(filename.c_str(), &currstat );
#else
      struct stat currstat;
      stat(filename.c_str(), &currstat);
#endif

      if(currstat.st_mtime == stored->filestat.st_mtime)
      {
         result = stored;
      }
      else
      {
         _loadData(filename);

         it = _contentMap.find(filename);

         if(it != _contentMap.end())
         {
            result = it->second;
         }
      }
   }
   else if((filename.length() > 0) && (filename != "0"))
   {
      _loadData(filename);

      it = _contentMap.find(filename);

      if(it != _contentMap.end())
      {
         result = it->second;
      }
   }

   result->addRef();
   pthread_mutex_unlock(&_mutex);
   return result;
}
