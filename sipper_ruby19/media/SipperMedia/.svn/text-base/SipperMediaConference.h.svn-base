#ifndef __SIPPER_CONFERENCE_H__
#define __SIPPER_CONFERENCE_H__

class SipperConfContributer
{
   int mediaId;
   int streamFlag;
};

class SipperConfStream
{
   int inputAmplifier;
   int outputAmplifier;

   short int *linearPcmInput;

   SipperConfContributer * outputContributers;
};

class SipperConfAttr
{
   int mediaId;

   SipperConfStream *fromPeer;
   SipperConfStream *fromStore;
};

class SipperMediaConference
{
   SipperConfAttr *confAttr;
};

#endif
