#include "SipperMediaLogger.h"
LOG("SipperMediaCodec");
#include "SipperMediaCodec.h"
#include "SipperMedia.h"
#include "SipperMediaTokenizer.h"
#include "SipperMediaPortable.h"
#include "vector"
#include "stdlib.h"

unsigned int SipperMediaCodec::silentThreshold = 0xff;
unsigned int SipperMediaCodec::silentDuration = 2;
unsigned int SipperMediaCodec::voiceDuration = 2;
unsigned int SipperMediaCodec::audioStopDuration = 5;

#if 0
unsigned char SipperMediaG711Codec::a2u[128] = {
   1,   3,   5,   7,   9,   11,   13,   15,
   16,   17,   18,   19,   20,   21,   22,   23,
   24,   25,   26,   27,   28,   29,   30,   31,
   32,   32,   33,   33,   34,   34,   35,   35,
   36,   37,   38,   39,   40,   41,   42,   43,
   44,   45,   46,   47,   48,   48,   49,   49,
   50,   51,   52,   53,   54,   55,   56,   57,
   58,   59,   60,   61,   62,   63,   64,   64,
   65,   66,   67,   68,   69,   70,   71,   72,
   73,   74,   75,   76,   77,   78,   79,   80,
   80,   81,   82,   83,   84,   85,   86,   87,
   88,   89,   90,   91,   92,   93,   94,   95,
   96,   97,   98,   99,   100,   101,   102,   103,
   104,   105,   106,   107,   108,   109,   110,   111,
   112,   113,   114,   115,   116,   117,   118,   119,
   120,   121,   122,   123,   124,   125,   126,   127};

unsigned char SipperMediaG711Codec::u2a[128] = {
   1,   1,   2,   2,   3,   3,   4,   4,
   5,   5,   6,   6,   7,   7,   8,   8,
   9,   10,   11,   12,   13,   14,   15,   16,
   17,   18,   19,   20,   21,   22,   23,   24,
   25,   27,   29,   31,   33,   34,   35,   36,
   37,   38,   39,   40,   41,   42,   43,   44,
   46,   48,   49,   50,   51,   52,   53,   54,
   55,   56,   57,   58,   59,   60,   61,   62,
   64,   65,   66,   67,   68,   69,   70,   71,
   72,   73,   74,   75,   76,   77,   78,   79,
   80,   82,   83,   84,   85,   86,   87,   88,
   89,   90,   91,   92,   93,   94,   95,   96,
   97,   98,   99,   100,   101,   102,   103,   104,
   105,   106,   107,   108,   109,   110,   111,   112,
   113,   114,   115,   116,   117,   118,   119,   120,
   121,   122,   123,   124,   125,   126,   127,   128};
#endif

unsigned char SipperMediaG711Codec::a2ulaw[256] = {
0x2a,0x2b,0x28,0x29,0x2e,0x2f,0x2c,0x2d,0x22,0x23,0x20,0x21,0x26,0x27,0x24,0x25,
0x39,0x3a,0x37,0x38,0x3d,0x3e,0x3b,0x3c,0x31,0x32,0x2f,0x30,0x35,0x36,0x33,0x34,
0xa,0xb,0x8,0x9,0xe,0xf,0xc,0xd,0x2,0x3,0x0,0x1,0x6,0x7,0x4,0x5,
0x1a,0x1b,0x18,0x19,0x1e,0x1f,0x1c,0x1d,0x12,0x13,0x10,0x11,0x16,0x17,0x14,0x15,
0x62,0x63,0x60,0x61,0x66,0x67,0x64,0x65,0x5d,0x5d,0x5c,0x5c,0x5f,0x5f,0x5e,0x5e,
0x74,0x76,0x70,0x72,0x7c,0x7e,0x78,0x7a,0x6a,0x6b,0x68,0x69,0x6e,0x6f,0x6c,0x6d,
0x48,0x49,0x46,0x47,0x4c,0x4d,0x4a,0x4b,0x40,0x41,0x3f,0x3f,0x44,0x45,0x42,0x43,
0x56,0x57,0x54,0x55,0x5a,0x5b,0x58,0x59,0x4f,0x4f,0x4e,0x4e,0x52,0x53,0x50,0x51,
0xaa,0xab,0xa8,0xa9,0xae,0xaf,0xac,0xad,0xa2,0xa3,0xa0,0xa1,0xa6,0xa7,0xa4,0xa5,
0xb9,0xba,0xb7,0xb8,0xbd,0xbe,0xbb,0xbc,0xb1,0xb2,0xaf,0xb0,0xb5,0xb6,0xb3,0xb4,
0x8a,0x8b,0x88,0x89,0x8e,0x8f,0x8c,0x8d,0x82,0x83,0x80,0x81,0x86,0x87,0x84,0x85,
0x9a,0x9b,0x98,0x99,0x9e,0x9f,0x9c,0x9d,0x92,0x93,0x90,0x91,0x96,0x97,0x94,0x95,
0xe2,0xe3,0xe0,0xe1,0xe6,0xe7,0xe4,0xe5,0xdd,0xdd,0xdc,0xdc,0xdf,0xdf,0xde,0xde,
0xf4,0xf6,0xf0,0xf2,0xfc,0xfe,0xf8,0xfa,0xea,0xeb,0xe8,0xe9,0xee,0xef,0xec,0xed,
0xc8,0xc9,0xc6,0xc7,0xcc,0xcd,0xca,0xcb,0xc0,0xc1,0xbf,0xbf,0xc4,0xc5,0xc2,0xc3,
0xd6,0xd7,0xd4,0xd5,0xda,0xdb,0xd8,0xd9,0xcf,0xcf,0xce,0xce,0xd2,0xd3,0xd0,0xd1
};

unsigned char SipperMediaG711Codec::u2alaw[256] = {
0x2a,0x2b,0x28,0x29,0x2e,0x2f,0x2c,0x2d,0x22,0x23,0x20,0x21,0x26,0x27,0x24,0x25,
0x3a,0x3b,0x38,0x39,0x3e,0x3f,0x3c,0x3d,0x32,0x33,0x30,0x31,0x36,0x37,0x34,0x35,
0xa,0xb,0x8,0x9,0xe,0xf,0xc,0xd,0x2,0x3,0x0,0x1,0x6,0x7,0x4,0x1a,
0x1b,0x18,0x19,0x1e,0x1f,0x1c,0x1d,0x12,0x13,0x10,0x11,0x16,0x17,0x14,0x15,0x6a,
0x68,0x69,0x6e,0x6f,0x6c,0x6d,0x62,0x63,0x60,0x61,0x66,0x67,0x64,0x65,0x7a,0x78,
0x7e,0x7f,0x7c,0x7d,0x72,0x73,0x70,0x71,0x76,0x77,0x74,0x75,0x4b,0x49,0x4f,0x4d,
0x42,0x43,0x40,0x41,0x46,0x47,0x44,0x45,0x5a,0x5b,0x58,0x59,0x5e,0x5f,0x5c,0x5d,
0x52,0x52,0x53,0x53,0x50,0x50,0x51,0x51,0x56,0x56,0x57,0x57,0x54,0x54,0x55,0x55,
0xaa,0xab,0xa8,0xa9,0xae,0xaf,0xac,0xad,0xa2,0xa3,0xa0,0xa1,0xa6,0xa7,0xa4,0xa5,
0xba,0xbb,0xb8,0xb9,0xbe,0xbf,0xbc,0xbd,0xb2,0xb3,0xb0,0xb1,0xb6,0xb7,0xb4,0xb5,
0x8a,0x8b,0x88,0x89,0x8e,0x8f,0x8c,0x8d,0x82,0x83,0x80,0x81,0x86,0x87,0x84,0x9a,
0x9b,0x98,0x99,0x9e,0x9f,0x9c,0x9d,0x92,0x93,0x90,0x91,0x96,0x97,0x94,0x95,0xea,
0xe8,0xe9,0xee,0xef,0xec,0xed,0xe2,0xe3,0xe0,0xe1,0xe6,0xe7,0xe4,0xe5,0xfa,0xf8,
0xfe,0xff,0xfc,0xfd,0xf2,0xf3,0xf0,0xf1,0xf6,0xf7,0xf4,0xf5,0xcb,0xc9,0xcf,0xcd,
0xc2,0xc3,0xc0,0xc1,0xc6,0xc7,0xc4,0xc5,0xda,0xdb,0xd8,0xd9,0xde,0xdf,0xdc,0xdd,
0xd2,0xd2,0xd3,0xd3,0xd0,0xd0,0xd1,0xd1,0xd6,0xd6,0xd7,0xd7,0xd4,0xd4,0xd5,0xd5
};

unsigned int SipperMediaG711Codec::u2linear[256] = {
0x8284,0x8684,0x8a84,0x8e84,0x9284,0x9684,0x9a84,0x9e84,
0xa284,0xa684,0xaa84,0xae84,0xb284,0xb684,0xba84,0xbe84,
0xc184,0xc384,0xc584,0xc784,0xc984,0xcb84,0xcd84,0xcf84,
0xd184,0xd384,0xd584,0xd784,0xd984,0xdb84,0xdd84,0xdf84,
0xe104,0xe204,0xe304,0xe404,0xe504,0xe604,0xe704,0xe804,
0xe904,0xea04,0xeb04,0xec04,0xed04,0xee04,0xef04,0xf004,
0xf0c4,0xf144,0xf1c4,0xf244,0xf2c4,0xf344,0xf3c4,0xf444,
0xf4c4,0xf544,0xf5c4,0xf644,0xf6c4,0xf744,0xf7c4,0xf844,
0xf8a4,0xf8e4,0xf924,0xf964,0xf9a4,0xf9e4,0xfa24,0xfa64,
0xfaa4,0xfae4,0xfb24,0xfb64,0xfba4,0xfbe4,0xfc24,0xfc64,
0xfc94,0xfcb4,0xfcd4,0xfcf4,0xfd14,0xfd34,0xfd54,0xfd74,
0xfd94,0xfdb4,0xfdd4,0xfdf4,0xfe14,0xfe34,0xfe54,0xfe74,
0xfe8c,0xfe9c,0xfeac,0xfebc,0xfecc,0xfedc,0xfeec,0xfefc,
0xff0c,0xff1c,0xff2c,0xff3c,0xff4c,0xff5c,0xff6c,0xff7c,
0xff88,0xff90,0xff98,0xffa0,0xffa8,0xffb0,0xffb8,0xffc0,
0xffc8,0xffd0,0xffd8,0xffe0,0xffe8,0xfff0,0xfff8,0x0,
0x7d7c,0x797c,0x757c,0x717c,0x6d7c,0x697c,0x657c,0x617c,
0x5d7c,0x597c,0x557c,0x517c,0x4d7c,0x497c,0x457c,0x417c,
0x3e7c,0x3c7c,0x3a7c,0x387c,0x367c,0x347c,0x327c,0x307c,
0x2e7c,0x2c7c,0x2a7c,0x287c,0x267c,0x247c,0x227c,0x207c,
0x1efc,0x1dfc,0x1cfc,0x1bfc,0x1afc,0x19fc,0x18fc,0x17fc,
0x16fc,0x15fc,0x14fc,0x13fc,0x12fc,0x11fc,0x10fc,0xffc,
0xf3c,0xebc,0xe3c,0xdbc,0xd3c,0xcbc,0xc3c,0xbbc,
0xb3c,0xabc,0xa3c,0x9bc,0x93c,0x8bc,0x83c,0x7bc,
0x75c,0x71c,0x6dc,0x69c,0x65c,0x61c,0x5dc,0x59c,
0x55c,0x51c,0x4dc,0x49c,0x45c,0x41c,0x3dc,0x39c,
0x36c,0x34c,0x32c,0x30c,0x2ec,0x2cc,0x2ac,0x28c,
0x26c,0x24c,0x22c,0x20c,0x1ec,0x1cc,0x1ac,0x18c,
0x174,0x164,0x154,0x144,0x134,0x124,0x114,0x104,
0xf4,0xe4,0xd4,0xc4,0xb4,0xa4,0x94,0x84,
0x78,0x70,0x68,0x60,0x58,0x50,0x48,0x40,
0x38,0x30,0x28,0x20,0x18,0x10,0x8,0x0
};

SipperMediaG711Codec::SipperMediaG711Codec(CodecType type, const std::string &sendFile, const std::string &recvFile)
{
   _lastVoiceTime.tv_sec = 0;
   _lastVoiceTime.tv_usec = 0;
   _lastSilentTime.tv_sec = 0;
   _lastSilentTime.tv_usec = 0;
   _voiceMode = false;

   _lastrecvTime.tv_sec = 0;
   _lastrecvTime.tv_usec = 0;
   _lastTimestamp = 0;

   _type = SipperMediaG711Codec::G711U;

   if(type == SipperMediaG711Codec::G711A)
   {
      _type = SipperMediaG711Codec::G711A;
   }

   logger.logMsg(TRACE_FLAG, 0, "CodecType[%d] SendFile[%s] RecvFile[%s]\n", 
                 _type, sendFile.c_str(), recvFile.c_str());

   _outfile = NULL;
   _outfilelen = 0;

   if(recvFile.length() > 0)
   {
      _outfile = fopen(recvFile.c_str(), "w+");

      if(_outfile == NULL)
      {
         logger.logMsg(ERROR_FLAG, 0, "Error opening File[%s]\n", recvFile.c_str());
      }
   }

   if(_outfile)
   {
      fprintf(_outfile, ".snd");

      int data = 24 + 12;
      data = htonl(data);
      fwrite(&data, sizeof(int), 1, _outfile);

      data = 0xFFFFFFFF;
      fwrite(&data, sizeof(int), 1, _outfile);

      data = 1;
      data = htonl(data);
      fwrite(&data, sizeof(int), 1, _outfile);

      data = 8000;
      data = htonl(data);
      fwrite(&data, sizeof(int), 1, _outfile);

      data = 1;
      data = htonl(data);
      fwrite(&data, sizeof(int), 1, _outfile);

      fprintf(_outfile, "SIPPERMEDIA");
      data = 0;
      fwrite(&data, 1, 1, _outfile);
   }

   _loadCommandLine(sendFile);

   audioContentHolder.setObj(SipperMediaFileLoader::getInstance().loadFile(""));
   _offset = 0;
   _wakeupTime.tv_sec = 0;
   _wakeupTime.tv_usec = 0;
}

void SipperMediaG711Codec::_loadCommandLine(const std::string &command)
{
   std::string delimiter = ",";
    std::insert_iterator<CommandList> inserter(_commandList, _commandList.end());

    SipperMediaTokenizer(command, delimiter, inserter);
   _commandLen = _commandList.size();
}

typedef std::vector<std::string> CommandVec;
typedef CommandVec::iterator CommandVecIt;

void SipperMediaG711Codec::_startCommandProcessing()
{
   std::string currcommand;

   if(_commandList.size() != 0)
   {
      currcommand = _commandList.front();
      _commandList.pop_front();

      if(currcommand.size() == 0)
      {
         _startCommandProcessing();
         return;
      }
   }
   else
   {
      currcommand = "PLAY_REPEAT 0 0";
   }

   SipperMediaPortable::trim(currcommand);

   logger.logMsg(TRACE_FLAG, 0, "Processing command [%s].\n", currcommand.c_str());

   CommandVec playcommand;
   std::string delimiter = " ";
   std::insert_iterator<CommandVec> inserter(playcommand, playcommand.begin());

   SipperMediaTokenizer(currcommand, delimiter, inserter);

   if(playcommand.size() == 0)
   {
      _startCommandProcessing();
      return;
   }

   std::string loccommand = playcommand[0];
   SipperMediaPortable::toUpper(playcommand[0]);

   if(playcommand[0] == "SLEEP")
   {
      std::string duration("0");
      if(playcommand.size() > 1)
      {
         duration = playcommand[1];
      }
      playcommand.clear();

      playcommand.push_back("PLAY_REPEAT");
      playcommand.push_back("0");
      playcommand.push_back(duration);
   }
   else if((playcommand[0] != "PLAY") && (playcommand[0] != "PLAY_REPEAT"))
   {
      playcommand.clear();
      playcommand.push_back("PLAY_REPEAT");
      playcommand.push_back(loccommand);
      playcommand.push_back("0");
   }

   while(playcommand.size() < 3)
   {
      playcommand.push_back("0");
   }

   if(playcommand[0] == "PLAY")
   {
      _repeatFlag = false;
   }
   else
   {
      _repeatFlag = true;
   }

   audioContentHolder.setObj(SipperMediaFileLoader::getInstance().loadFile(playcommand[1]));
   _offset = 0;

   int duration = atoi(playcommand[2].c_str());
   
   if(duration == 0)
   {
      _wakeupTime.tv_sec = 0x7FFFFFFF;
      _wakeupTime.tv_usec = 0;
   }
   else
   {
      SipperMediaPortable::getTimeOfDay(&_wakeupTime);
      _wakeupTime.tv_sec += duration;
   }
}

SipperMediaG711Codec::~SipperMediaG711Codec()
{
   if(_outfile != NULL)
   {
      fseek(_outfile, 8, SEEK_SET);
      int data = htonl(_outfilelen);
      fwrite(&data, sizeof(int), 1, _outfile);
      fclose(_outfile);

      _outfile = NULL;
   }
}

void SipperMediaG711Codec::handleTimer(struct timeval &currtime)
{
   SipperRTPMedia *media = static_cast<SipperRTPMedia *>(_media);
   SipperMediaRTPHeader header = media->lastSentHeader;
   header.setVersion(2);
   header.setPadding(0);
   header.setExtension(0);
   header.setCSRCCount(0);
   header.setMarker(0);
   header.setPayloadNum(sendPayloadNum);
   header.setSequence(header.getSequence() + 1);

   if(_lastTimestamp == 0)
   {
      _lastTimestamp = header.getTimeStamp();
   }
   _lastTimestamp += 160;
   header.setTimeStamp(_lastTimestamp);

   SipperMediaFileContent *g711Content = dynamic_cast<SipperMediaFileContent *>(audioContentHolder.getObj());

   unsigned char *dataptr = g711Content->data + _offset;

   bool rollover = false;
   bool deletecontent = false;
   if(_offset + 160 >= g711Content->len)
   {
      unsigned char *tmp = new unsigned char[160];
      memset(tmp, 0xFF, 160);
      memcpy(tmp, dataptr, g711Content->len - _offset);
      dataptr = tmp;
      deletecontent = true;
      rollover = true;
      _offset = 0;
   }
   else
   {
      _offset += 160;
   }

   if(_type == SipperMediaG711Codec::G711A)
   {
      if(!deletecontent)
      {
         unsigned char *tmp = new unsigned char[160];
         memcpy(tmp, dataptr, 160);
         dataptr = tmp;
         deletecontent = true;
      }

      for(int idx = 0; idx < 160; idx++)
      {
         dataptr[idx] = u2alaw[dataptr[idx]];
      }
   }

   media->sendRTPPacket(header, dataptr, 160);

   if(deletecontent)
   {
      delete []dataptr;
   }

   if(rollover && (!_repeatFlag))
   {
       logger.logMsg(TRACE_FLAG, 0, "End of play.\n");
      _startCommandProcessing();
      return;
   }

   if(SipperMediaPortable::isGreater(&currtime, &_wakeupTime))
   {
       logger.logMsg(TRACE_FLAG, 0, "End of duration[%d-%d] [%d-%d].\n",
                      currtime.tv_sec, currtime.tv_usec, _wakeupTime.tv_sec,
                      _wakeupTime.tv_usec);
      _startCommandProcessing();
      return;
   }
}

void SipperMediaG711Codec::checkActivity(struct timeval &currtime)
{
   if((_lastrecvTime.tv_sec == 0) && (_lastrecvTime.tv_usec == 0))
   {
      return;
   }

   struct timeval tolerance = _lastrecvTime;
   tolerance.tv_sec += audioStopDuration;

   if(SipperMediaPortable::isGreater(&currtime, &tolerance))
   {
      char evt[200];
      sprintf(evt, "CODEC=%d;EVENT=AUDIOSTOPPED", this->recvPayloadNum);
      _media->sendEvent(evt);
      _lastrecvTime.tv_sec = 0;
      _lastrecvTime.tv_usec = 0;
   }

   if(_voiceMode)
   {
      if(SipperMediaPortable::isGreater(&_lastSilentTime, &_lastVoiceTime))
      {
         tolerance = _lastVoiceTime;
         tolerance.tv_usec += silentDuration;
         if(tolerance.tv_usec >= 1000000)
         {
            tolerance.tv_sec += (tolerance.tv_usec / 1000000);
            tolerance.tv_usec %= 1000000;
         }

         if(SipperMediaPortable::isGreater(&currtime, &tolerance))
         {
            _voiceMode = false;
            _lastSilentTime = currtime;

            char evt[200];
            sprintf(evt, "CODEC=%d;EVENT=VOICE_ACTIVITY_STOPPED", this->recvPayloadNum);
            _media->sendEvent(evt);
         }
      }
   }
   else
   {
      if(SipperMediaPortable::isGreater(&_lastVoiceTime, &_lastSilentTime))
      {
         tolerance = _lastSilentTime;
         tolerance.tv_usec += voiceDuration;
         if(tolerance.tv_usec >= 1000000)
         {
            tolerance.tv_sec += (tolerance.tv_usec / 1000000);
            tolerance.tv_usec %= 1000000;
         }


         if(SipperMediaPortable::isGreater(&currtime, &tolerance))
         {
            _voiceMode = true;

            char evt[200];
            sprintf(evt, "CODEC=%d;EVENT=VOICE_ACTIVITY_DETECTED", this->recvPayloadNum);
            _media->sendEvent(evt);
         }
      }
   }
}

void SipperMediaG711Codec::processReceivedRTPPacket(struct timeval &currtime, const unsigned char *payload, unsigned int payloadlen)
{
   if((_lastrecvTime.tv_sec == 0) && (_lastrecvTime.tv_usec == 0))
   {
      char evt[200];
      sprintf(evt, "CODEC=%d;EVENT=AUDIOSTARTED", this->recvPayloadNum);
      _media->sendEvent(evt);
   }

   _lastrecvTime = currtime;

   unsigned char *newpayload = const_cast<unsigned char *>(payload);

   if(_type == SipperMediaG711Codec::G711A)
   {
      newpayload = new unsigned char[payloadlen];

      for(unsigned int idx = 0; idx < payloadlen; idx++)
      {
         newpayload[idx] = a2ulaw[payload[idx]];
      }
   }

   unsigned int maxval = 0;
   int silentCount = 0;
   for(unsigned int idx = 0; idx < payloadlen; idx++)
   {
      signed short currval = u2linear[newpayload[idx]];
      currval = abs(currval);

      if(currval <= silentThreshold)
      {
         silentCount++;
      }
   }

   if(silentCount > (payloadlen * 9 /10))
   {
      //Current packet is silent.
      _lastSilentTime = currtime;
   }
   else
   {
      //Current packet is having voice.
      _lastVoiceTime = currtime;
   }

   if(_outfile != NULL)
   {
      fwrite(newpayload, payloadlen, 1, _outfile);
      _outfilelen += payloadlen;
   }

   if(_type == G711A)
   {
      delete []newpayload;
   }
}

SipperMediaDTMFCodec::SipperMediaDTMFCodec(const std::string &sendFile, const std::string &recvFile)
{
   _sendState = STATE_NONE;
   _listLen = 0;

   if(sendFile.length() > 0)
   {
      FILE *fp = fopen(sendFile.c_str(), "r");

      if(fp != NULL)
      {
         char data[201]; data[200] = '\0';
         while(fgets(data, 200, fp) != NULL)
         {
            sendDtmf(data);
         }

         fclose(fp);
      }
   }
}

void SipperMediaDTMFCodec::sendDtmf(const std::string & command, bool checkFlag)
{
   std::string delimiter = ",";
    std::insert_iterator<CommandList> inserter(_commandList, _commandList.end());

    SipperMediaTokenizer(command, delimiter, inserter);
   _listLen = _commandList.size();
}

void SipperMediaDTMFCodec::handleTimer(struct timeval &currtime)
{
   switch(_sendState)
   {
   case STATE_NONE:
      {
         if(_listLen == 0) return;
         std::string currcommand = _commandList.front();
         _commandList.pop_front();
         _listLen--;

         SipperMediaPortable::toUpper(currcommand);
         SipperMediaPortable::trim(currcommand);

         char *command = (char *)currcommand.c_str();
         char dummy[100];
         if(currcommand.length() > 50)
         {
            command[50] = '\0';
         }

         if(*command == 'S')
         {
            logger.logMsg(TRACE_FLAG, 0, 
                          "Processing DTMF SLEEP command [%s].\n", currcommand.c_str());
            int sleepDuration;
            sscanf(command, "%s %d", dummy, &sleepDuration);
            _wakeupTime = currtime;
            _wakeupTime.tv_sec += sleepDuration;
            _sendState = STATE_SLEEPING;
         }
         else
         {
            int toSend = atoi(command);

            const char firstChar = *command;

            if(toSend == 0)
            {
               if(firstChar == '*') toSend = 10;
               else if(firstChar == '#') toSend = 11;
               else if(firstChar == 'A') toSend = 12;
               else if(firstChar == 'B') toSend = 13;
               else if(firstChar == 'C') toSend = 14;
               else if(firstChar == 'D') toSend = 15;
               else if(firstChar == 'F') toSend = 16;
            }

            logger.logMsg(TRACE_FLAG, 0, 
                          "Processing DTMF Digit[%d] command[%s].\n", 
                          toSend, currcommand.c_str());
            SipperRTPMedia *media = static_cast<SipperRTPMedia *>(_media);
            _dtmfRTPHeader = media->lastSentHeader;
            _dtmfRTPHeader.setVersion(2);
            _dtmfRTPHeader.setPadding(0);
            _dtmfRTPHeader.setExtension(0);   
            _dtmfRTPHeader.setCSRCCount(0);
            _dtmfRTPHeader.setMarker(1);
            _dtmfRTPHeader.setPayloadNum(sendPayloadNum);
            _dtmfRTPHeader.setSequence(media->lastSentHeader.getSequence() + 1);
            _dtmfPacket.setEndBit(0);
            _dtmfPacket.setReserve(0);
            _dtmfPacket.setEvent(toSend);
            _dtmfPacket.setVolume(12);
            _dtmfPacket.setDuration(0);
            int rtpPayload = htonl(_dtmfPacket.first);
            media->sendRTPPacket(_dtmfRTPHeader, (unsigned char *)&rtpPayload, 4);
            _dtmfRTPHeader.setMarker(0);
            _dtmfPacketCount = 1;
            _sendState = STATE_SENDING;
         }
      };
      break;
   case STATE_SLEEPING:
      {
         if(SipperMediaPortable::isGreater(&currtime, &_wakeupTime))
         {
            _sendState = STATE_NONE;
         }
      };
      break;
   case STATE_SENDING:
      {
         SipperRTPMedia *media = static_cast<SipperRTPMedia *>(_media);
         _dtmfRTPHeader.setSequence(media->lastSentHeader.getSequence() + 1);

         if(_dtmfPacketCount < 7)
         {
            _dtmfPacket.setDuration(_dtmfPacket.getDuration() + 160);
         }
         else if(_dtmfPacketCount == 7)
         {
            _dtmfPacket.setDuration(_dtmfPacket.getDuration() + 160);
            _dtmfPacket.setEndBit(1);
         }
         else if(_dtmfPacketCount == 10)
         {
            _sendState = STATE_NONE;
         }

         int rtpPayload = htonl(_dtmfPacket.first);
         media->sendRTPPacket(_dtmfRTPHeader, (unsigned char *)&rtpPayload, 4);
         _dtmfPacketCount++;
      };
      break;
   }
}

void SipperMediaDTMFCodec::checkActivity(struct timeval &currtime)
{
   return;
}

void SipperMediaDTMFCodec::processReceivedRTPPacket(struct timeval &currtime, const unsigned char *payload, unsigned int payloadlen)
{
   if(payloadlen == 4)
   {
      SipperRTPMedia *media = static_cast<SipperRTPMedia *>(_media);
      SipperMediaRTPHeader header = media->lastRecvHeader;
      if(media->lastDtmfTimestamp == header.getTimeStamp())
      {
         return;
      }

      media->lastDtmfTimestamp = header.getTimeStamp();

      unsigned char dtmfval = payload[0];
      dtmfval &= 0x1F;
      char digit = '0' + dtmfval;

      if(digit > '9')
      {
         if(dtmfval == 10) digit = '*';
         else if(dtmfval == 11) digit = '#';
         else if(dtmfval == 12) digit = 'A';
         else if(dtmfval == 13) digit = 'B';
         else if(dtmfval == 14) digit = 'C';
         else if(dtmfval == 15) digit = 'D';
         else if(dtmfval == 16) digit = 'F';
         else 
         {
            logger.logMsg(ERROR_FLAG, 0, 
                          "Invalid dtmf digit received. [%d]\n", payload[0]);
            return;
         }
      }

      char evt[200];
      sprintf(evt, "CODEC=%d;EVENT=DTMFRECEIVED;DTMF=%c", this->recvPayloadNum, digit);
      _media->sendEvent(evt);
   }
}

