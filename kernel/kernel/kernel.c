#include <stdint.h>

#define MAGIC 0x36d76289

void kernel_main(uint32_t magic, uint32_t info) {
  if (magic != MAGIC) {
    while (1) {
      __asm__ volatile("hlt");
    }
  }

  while (1) {
    __asm__ volatile("hlt");
  }
}
