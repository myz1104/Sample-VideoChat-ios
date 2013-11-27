// Copyright (c) 2012 Alex Wiltschko
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


#include "QBRingBuffer.h"


#pragma mark -
#pragma mark Constructor & Destructor

QBRingBuffer::QBRingBuffer(SInt64 bufferLength, SInt64 numChannels) : 
mSizeOfBuffer(bufferLength)
{
	
	if (numChannels > kMaxNumChannels)
		mNumChannels = kMaxNumChannels;
	else if (numChannels <= 0)
		mNumChannels = 1;
	else
		mNumChannels = numChannels;
	
	mData = (float **)calloc(numChannels, sizeof(float *));
    
	for (int i=0; i < numChannels; ++i) {
		mData[i] = (float *)calloc(bufferLength, sizeof(float));
		mLastWrittenIndex[i] = 0;
		mLastReadIndex[i] = 0;
        mNumUnreadFrames[i] = 0;
	}
}

QBRingBuffer::~QBRingBuffer() 
{
    for (int i=0; i<mNumChannels; i++) {
        free(mData[i]);
    }
}


#pragma mark -
#pragma mark Add

void QBRingBuffer::AddNewSInt16AudioBuffer(const AudioBuffer aBuffer)
{
		
	int numChannelsHere = aBuffer.mNumberChannels;
	int numFrames = aBuffer.mDataByteSize/(numChannelsHere*sizeof(SInt16));
	SInt16 *newData = (SInt16 *)aBuffer.mData;
	
	SInt64 idx;
		
	for (int iChannel = 0; iChannel < mNumChannels; ++iChannel) {
		for (int i=0; i < numFrames; ++i) {
			idx = (i + mLastWrittenIndex[iChannel]) % (mSizeOfBuffer);
			mData[iChannel][idx] = (float)newData[i*numChannelsHere + iChannel];
		}
		
		mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + numFrames) % (mSizeOfBuffer);
        mNumUnreadFrames[iChannel] = mNumUnreadFrames[iChannel] + numFrames;
        if (mNumUnreadFrames[iChannel] >= mSizeOfBuffer) mNumUnreadFrames[iChannel] = mSizeOfBuffer;
	}
}

void QBRingBuffer::AddNewSInt16Data(const SInt16 *newData, const SInt64 numFrames, const SInt64 whichChannel)
{
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = (float)newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void QBRingBuffer::AddNewFloatData(const float *newData, const SInt64 numFrames, const SInt64 whichChannel)
{
	
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void QBRingBuffer::AddNewDoubleData(const double *newData, const SInt64 numFrames, const SInt64 whichChannel)
{
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = (float)newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void QBRingBuffer::AddNewInterleavedFloatData(const float *newData, const SInt64 numFrames, const SInt64 numChannelsHere)
{
	NSInteger numChannelsToCopy = (numChannelsHere <= mNumChannels) ? numChannelsHere : mNumChannels;
	float zero = 0.0f;
	
	for (int iChannel = 0; iChannel < numChannelsToCopy; ++iChannel) {
		
		if (numFrames + mLastWrittenIndex[iChannel] < mSizeOfBuffer) { // if our new set of samples won't overrun the edge of the buffer
			vDSP_vsadd((float *)&newData[iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][mLastWrittenIndex[iChannel]], 
					   1, 
					   numFrames);
		}
			
		else {															// if we will overrun, then we need to do two separate copies.
			NSInteger numSamplesInFirstCopy = mSizeOfBuffer - mLastWrittenIndex[iChannel];
			NSInteger numSamplesInSecondCopy = numFrames - numSamplesInFirstCopy;
			
			vDSP_vsadd((float *)&newData[iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][mLastWrittenIndex[iChannel]], 
					   1, 
					   numSamplesInFirstCopy);
			
			vDSP_vsadd((float *)&newData[numSamplesInFirstCopy*numChannelsHere + iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][0], 
					   1, 
					   numSamplesInSecondCopy);
		}
	
		mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + numFrames) % (mSizeOfBuffer);
        mNumUnreadFrames[iChannel] = (mNumUnreadFrames[iChannel] + numFrames);
        if (mNumUnreadFrames[iChannel] >= mSizeOfBuffer)
		{
			mNumUnreadFrames[iChannel] = mSizeOfBuffer;
		}
	}
}


#pragma mark -
#pragma mark Fetch data

void QBRingBuffer::FetchFreshData2(float *outData, SInt64 numFrames, SInt64 whichChannel, SInt64 stride)
{
    if (mLastWrittenIndex[whichChannel] - numFrames >= 0) { // if we're requesting samples that won't go off the left end of the ring buffer, then go ahead and copy them all out.
        
        UInt32 idx = (UInt32)(mLastWrittenIndex[whichChannel] - numFrames);
        float zero = 0.0f;
        vDSP_vsadd(&mData[whichChannel][idx], 
                   1, 
                   &zero, 
                   outData, 
                   stride, 
                   numFrames);
    }
    
    else { // if we will overrun, then we need to do two separate copies.
        
        // The copy that bleeds off the left, and cycles back to the right of the ring buffer
        NSInteger numSamplesInFirstCopy = numFrames - mLastWrittenIndex[whichChannel];
        // The copy that starts at the beginning, and proceeds to the end.
        NSInteger numSamplesInSecondCopy = mLastWrittenIndex[whichChannel];
        
        
        float zero = 0.0f;
        UInt32 firstIndex = (UInt32)(mSizeOfBuffer - numSamplesInFirstCopy);
        vDSP_vsadd(&mData[whichChannel][firstIndex],
                   1, 
                   &zero, 
                   &outData[0], 
                   stride, 
                   numSamplesInFirstCopy);

        vDSP_vsadd(&mData[whichChannel][0],
                   1, 
                   &zero, 
                   &outData[numSamplesInFirstCopy*stride],
                   stride, 
                   numSamplesInSecondCopy);
        
    }
}

void QBRingBuffer::FetchData(float *outData, SInt64 numFrames, SInt64 whichChannel, SInt64 stride)
{
    NSInteger idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (mLastReadIndex[whichChannel] + i) % (mSizeOfBuffer);
		outData[i*stride] = mData[whichChannel][idx];
		//
		mData[whichChannel][idx] = 0.0;
	}
	
    mLastReadIndex[whichChannel] = (mLastReadIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    
    mNumUnreadFrames[whichChannel] -= numFrames;
    if (mNumUnreadFrames[whichChannel] <= 0) mNumUnreadFrames[whichChannel] = 0;

	
}

void QBRingBuffer::FetchInterleavedData(float *outData, SInt64 numFrames, SInt64 numChannels)
{
    for (int iChannel=0; iChannel < numChannels; ++iChannel) {
        FetchData(&outData[iChannel], numFrames, iChannel, numChannels);
    }

}

void QBRingBuffer::FetchFreshData(float *outData, SInt64 numFrames, SInt64 whichChannel, SInt64 stride)
{

	NSInteger idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (mLastWrittenIndex[whichChannel] - numFrames + i) % (mSizeOfBuffer);
		outData[i*stride] = mData[whichChannel][idx];
	}
	
	mLastReadIndex[whichChannel] = mLastWrittenIndex[whichChannel];
    mNumUnreadFrames[whichChannel] = 0; // Reading at the front of the buffer resets old data
}


#pragma mark -
#pragma mark Move index

void QBRingBuffer::SeekWriteHeadPosition(SInt64 offset, int iChannel)
{
    mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + offset) % (mSizeOfBuffer);
}

void QBRingBuffer::SeekReadHeadPosition(SInt64 offset, int iChannel)
{
    mLastReadIndex[iChannel] = (mLastReadIndex[iChannel] + offset) % (mSizeOfBuffer);
}


#pragma mark -
#pragma mark Num new frames

SInt64 QBRingBuffer::NumNewFrames(SInt64 lastReadFrame, int iChannel)
{
	NSInteger numNewFrames = mLastWrittenIndex[iChannel] - lastReadFrame;
	if (numNewFrames < 0) numNewFrames += mSizeOfBuffer;
	
	return (SInt64)numNewFrames;
}


#pragma mark -
#pragma mark Analytics

float QBRingBuffer::Mean(const SInt64 whichChannel)
{
	float mean;
	vDSP_meanv(mData[whichChannel],1,&mean,mSizeOfBuffer);
	return mean;
}


float QBRingBuffer::Max(const SInt64 whichChannel)
{
	float max;
	vDSP_maxv(mData[whichChannel],1,&max,mSizeOfBuffer);
	return max;
}


float QBRingBuffer::Min(const SInt64 whichChannel)
{
	float min;
	vDSP_minv(mData[whichChannel],1,&min,mSizeOfBuffer);
	return min;	
}


#pragma mark -
#pragma mark clearing

void QBRingBuffer::Clear()
{
	for (int i=0; i < mNumChannels; ++i) {
		memset(mData[i], 0, sizeof(float)*mSizeOfBuffer);
		mLastWrittenIndex[i] = 0;
		mLastReadIndex[i] = 0;
        mNumUnreadFrames[i] = 0;
	}
}

void QBRingBuffer::PrintData(){
    NSMutableString *res = [NSMutableString string];
    for(int y=0; y<mSizeOfBuffer; ++y){
        [res appendFormat:@"%f ",  mData[0][y]];
    }
    QBDLog(@"mData: %@", res);
}

