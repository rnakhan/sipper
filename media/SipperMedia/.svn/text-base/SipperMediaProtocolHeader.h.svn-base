#ifndef __SIPPER_MEDIA_PROTOCOL_HEADER_H__
#define __SIPPER_MEDIA_PROTOCOL_HEADER_H__

struct SipperMediaRTPHeader
{
   int first;
   int timestamp;
   int ssrc;
   int csrc[16];

   SipperMediaRTPHeader()
   {
      first = 0;
      timestamp = 0;
      ssrc = 0;

      for(int idx = 0; idx < 16; idx++)
      {
         csrc[idx] = 0;
      }
   }

   int getVersion()
   {
      return (first >> 30) & 0x3;
   }

   void setVersion(int version)
   {
      version &= 0x3;
      first &= 0x3FFFFFFF;
      first |= (version << 30);
   }

   int getPadding()
   {
      return (first >> 29) & 0x1;
   }

   void setPadding(int padding)
   {
      padding &= 0x1;
      first &= 0xDFFFFFFF;
      first |= (padding << 29);
   }

   int getExtension()
   {
      return (first >> 28) & 0x1;
   }

   void setExtension(int extension)
   {
      extension &= 0x1;
      first &= 0xEFFFFFFF;
      first |= (extension << 28);
   }

   int getCSRCCount()
   {
      return (first >> 24) & 0xF;
   }

   void setCSRCCount(int csrccount)
   {
      csrccount &= 0xF;
      first &= 0xF0FFFFFF;
      first |= (csrccount << 24);
   }

   int getMarker()
   {
      return (first >> 23) & 0x1;
   }

   void setMarker(int marker)
   {
      marker &= 0x1;
      first &= 0xFF7FFFFF;
      first |= (marker << 23);
   }

   int getPayloadNum()
   {
      return (first >> 16) & 0x7F;
   }

   void setPayloadNum(int payloadnum)
   {
      payloadnum &= 0x7F;
      first &= 0xFF80FFFF;
      first |= (payloadnum << 16);
   }

   int getSequence()
   {
      return (first & 0xFF);
   }

   void setSequence(int sequence)
   {
      sequence &= 0xFF;
      first &= 0xFFFFFF00;
      first |= sequence;
   }

   int getTimeStamp()
   {
      return timestamp;
   }

   void setTimeStamp(int inTimestamp)
   {
      timestamp = inTimestamp;
   }

   int getSSRC()
   {
      return ssrc;
   }

   void setSSRC(int inssrc)
   {
      ssrc = inssrc;
   }

   int getCSRC(int idx)
   {
      idx &= 0xF;

      return csrc[idx];
   }

   void setCSRC(int idx, int csrcval)
   {
      idx &= 0xF;

      csrc[idx] = csrcval;
   }
};


struct SipperMediaDTMFPacket
{
   int first;

   SipperMediaDTMFPacket()
   {
      first = 0;
   }

   int getEvent()
   {
      return (first >> 24) & 0xFF;
   }

   void setEvent(int event)
   {
      event &= 0xFF;
      first &= 0x00FFFFFF;
      first |= (event << 24);
   }

   int getEndBit()
   {
      return (first >> 23) & 0x1;
   }

   void setEndBit(int endbit)
   {
      endbit &= 0x1;
      first &= 0xFF7FFFFF;
      first |= (endbit << 23);
   }

   int getReserve()
   {
      return (first >> 22) & 0x1;
   }

   void setReserve(int reserve)
   {
      reserve &= 0x1;
      first &= 0xFFBFFFFF;
      first |= (reserve << 22);
   }

   int getVolume()
   {
      return (first >> 16) & 0x3F;
   }

   void setVolume(int volume)
   {
      volume &= 0x3F;
      first &= 0xFFC0FFFF;
      first |= (volume << 16);
   }

   int getDuration()
   {
      return (first & 0xFFFF);
   }

   void setDuration(int duration)
   {
      duration &= 0xFFFF;
      first &= 0xFFFF0000;
      first |= duration;
   }
};

#endif
