#ifndef THREADSAFEQUEUE_H
#define THREADSAFEQUEUE_H

#include <chrono>
#include <condition_variable>
#include <mutex>
#include <queue>
#include <optional>
#include <cassert>

/**
 * Simple threadsafe queue supporting wait dequeue
 */
namespace qopenhd {
template<class T>
class ThreadsafeQueue {
 public:
  explicit ThreadsafeQueue(int capacity):m_capacity(capacity){};
  // Enqueues a new element. Return true on success, false otherwise
  bool try_enqueue(T element){
    std::unique_lock<std::mutex> lk(mtx);
    if(queue.size()>=m_capacity){
      return false;
    }
    queue.push(element);
    cv.notify_one();
    return true;
  }
  // Wait up to timeout until element is available.
  template<typename Rep, typename Period>
  std::optional<T> wait_dequeue_timed(std::chrono::duration<Rep, Period> const& timeout){
    std::unique_lock<std::mutex> ul(mtx);
    if(!queue.empty()){
      auto tmp=queue.front();
      queue.pop();
      return tmp;
    }
    const auto res=cv.wait_for(ul,timeout,[this](){
      return !queue.empty();
    });
    if(!res){
      // Timeout
      return std::nullopt;
    }
    assert(!queue.empty());
    auto tmp=queue.front();
    queue.pop();
    return tmp;
  }
private:
 const int m_capacity;
 std::queue<T> queue;
 std::mutex mtx;
 std::condition_variable cv;
};
}

#endif // THREADSAFEQUEUE_H
