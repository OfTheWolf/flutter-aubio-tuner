#include <jni.h>
#include "aubiopitch.h"

void Java_com_ofthewolf_aubiotuner_MainActivity_initPitch(JNIEnv * env, jobject obj, jint sampleRate, jint bufferSize)
{
    unsigned int win_s = (unsigned int) bufferSize; // window size
    unsigned int hop_s = win_s / 4; // hop size
    unsigned int samplerate = (unsigned int) sampleRate; // samplerate

    init_aubio(win_s, samplerate);
}

jfloat Java_com_ofthewolf_aubiotuner_MainActivity_getPitch(JNIEnv * env, jobject obj, jfloatArray inputArray)
{
    jsize len = (*env)->GetArrayLength(env, inputArray);

    jfloat *body = (*env)->GetFloatArrayElements(env, inputArray, 0);
    smpl_t freq = process_aubio(body, len);
    
    return freq;
}


