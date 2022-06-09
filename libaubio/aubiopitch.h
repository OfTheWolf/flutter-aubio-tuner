#include <stdio.h>  // for fprintf
#include <stdlib.h> // for exit
#include <aubio.h>

typedef void (*aubio_process_callback_t) (smpl_t freq);

void init_aubio(uint_t _buffer_size, uint_t _samplerate);
void delete_aubio(void);
smpl_t process_aubio(smpl_t *input, int nframes);
