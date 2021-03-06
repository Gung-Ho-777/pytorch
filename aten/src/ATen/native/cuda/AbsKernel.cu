#include <ATen/native/UnaryOps.h>
#include <ATen/native/cuda/Loops.cuh>
#include <ATen/Dispatch.h>
#include <ATen/native/DispatchStub.h>
#include <ATen/native/TensorIterator.h>

namespace at { namespace native {

// We manually overload abs because std::abs does not work with thrust::complex types and ROCm.
template<typename scalar_t>
__device__ static inline scalar_t abs_wrapper(scalar_t v) {
  return ::abs(v);
}

template<typename T>
__device__ static inline c10::complex<T> abs_wrapper(c10::complex<T> v) {
  return std::abs(v);
}

__device__ static inline uint8_t abs_wrapper(uint8_t v) {
  return v;
}

__device__ static inline bool abs_wrapper(bool v) {
  return v;
}

template<typename scalar_t>
struct AbsFunctor {
  __device__ __forceinline__ scalar_t operator() (scalar_t a) const {
    return abs_wrapper(a);
  }
};

void abs_kernel_cuda(TensorIterator& iter) {
  AT_DISPATCH_ALL_TYPES_AND_COMPLEX_AND3(ScalarType::Half, ScalarType::BFloat16, ScalarType::Bool, iter.dtype(), "abs_cuda", [&]() {
    AT_SKIP_BFLOAT16_IF_NOT_ROCM(scalar_t, "abs_cuda", [&] {
      gpu_kernel(iter, AbsFunctor<scalar_t>());
    });
  });
}

REGISTER_DISPATCH(abs_stub, &abs_kernel_cuda);

}} // namespace at::native
