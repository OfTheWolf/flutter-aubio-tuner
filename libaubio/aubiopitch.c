/*
  Copyright (C) 2003-2013 Paul Brossier <piem@aubio.org>
  This file is part of aubio.
  aubio is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  aubio is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
  along with aubio.  If not, see <http://www.gnu.org/licenses/>.
*/
#include "aubiopitch.h" // for exit

aubio_pitch_t *o;
fvec_t *pitch_buffer;
fvec_t *input_buffer;
uint_t samplerate = 44100;
uint_t buffer_size = 1024;
uint_t hop_size = 512;
char_t *pitch_unit = "default";
char_t *pitch_method = "yin";
smpl_t pitch_tolerance = 0.7f; // will be set if != 0.
smpl_t silence_threshold = -90.f;

void init_aubio(uint_t _buffer_size, uint_t _samplerate){
  samplerate = _samplerate;
  buffer_size = _buffer_size;
  int ret = 0;

  input_buffer = new_fvec (buffer_size);
  pitch_buffer = new_fvec(1);

  o = new_aubio_pitch(pitch_method, buffer_size, hop_size, samplerate);

  if (pitch_tolerance != 0.)
    aubio_pitch_set_tolerance(o, pitch_tolerance);
  if (silence_threshold != -90.)
    aubio_pitch_set_silence(o, silence_threshold);
  if (pitch_unit != NULL)
    aubio_pitch_set_unit(o, pitch_unit);
    
}

void delete_aubio(){
  del_aubio_pitch(o);
  del_fvec(pitch_buffer);
  del_fvec(input_buffer);
}

smpl_t process_aubio(smpl_t *input, int nframes) {
  for (int j = 0; j < nframes; j++) {
    fvec_set_sample(input_buffer, input[j], j);
  }

  aubio_pitch_do(o, input_buffer, pitch_buffer);

  smpl_t freq = fvec_get_sample(pitch_buffer, 0);
  return freq;
}
