#!/usr/bin/env python3
"""Synthesize original, deterministic offline game audio (no sampled recordings)."""
import math
import pathlib
import random
import struct
import wave
RATE=22050
ROOT=pathlib.Path(__file__).resolve().parents[1]/'assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)
def write(name,samples):
    with wave.open(str(ROOT/name),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*32767)) for x in samples))
def tone(freq,duration,volume=.18):
    return [volume*math.sin(2*math.pi*freq*i/RATE)*(1-math.exp(-i/(RATE*.006)))*math.exp(-i/(RATE*duration*.35)) for i in range(int(RATE*duration))]
def melody(name,notes,step=.13):
    data=[0.0]*int(RATE*(len(notes)*step+.25))
    for idx,freq in enumerate(notes):
        for i,v in enumerate(tone(freq,.25)):
            at=int(idx*step*RATE)+i
            if at<len(data):data[at]+=v
    write(name,data)
melody('point.wav',[659.25,880],.08)
melody('flap.wav',[392,587.33],.045)
melody('ready.wav',[523.25],.1)
melody('go.wav',[523.25,659.25,783.99],.08)
melody('finish.wav',[659.25,523.25,392],.12)
melody('unlock.wav',[523.25,659.25,783.99,1046.5],.11)
# A quiet 16-second marimba-like loop. All notes decay before the loop boundary.
notes=[523.25,0,659.25,783.99,0,659.25,587.33,0,523.25,0,440,523.25,0,659.25,587.33,0,
       392,0,523.25,659.25,0,587.33,523.25,0,440,0,523.25,587.33,0,392,0,0]
data=[0.0]*(RATE*16)
for j,freq in enumerate(notes):
    if not freq:continue
    for i,v in enumerate(tone(freq,.48,.11)):
        at=int(j*.5*RATE)+i
        if at<len(data):data[at]+=v
write('sky_club.wav',data)
