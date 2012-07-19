#ifndef __SIPPER_MEDIA_TOKENIZER_H__
#define __SIPPER_MEDIA_TOKENIZER_H__

#include <iterator>

template <typename BaseData, typename OutputIterator>
OutputIterator SipperMediaTokenizer(const BaseData &data, const BaseData &pattern,
                                    OutputIterator result)
{
   typename BaseData::const_iterator dataStart = data.begin();
   typename BaseData::const_iterator dataEnd   = data.end();
   typename BaseData::const_iterator patternStart = pattern.begin();
   typename BaseData::const_iterator patternEnd   = pattern.end();

   typename BaseData::const_iterator dataCurr = dataStart;

   while(dataCurr != dataEnd)
   {
      typename BaseData::const_iterator patternCurr = patternStart;

      while(patternCurr != patternEnd)
      {
         if(*dataCurr == *patternCurr)
         {
            *result++ = BaseData(dataStart, dataCurr);
            dataStart = dataCurr;
            dataStart++;
            break;
         }

         ++patternCurr;
      }

      ++dataCurr;
   }

   *result++ = BaseData(dataStart, dataCurr);

   return result;
}

#endif
