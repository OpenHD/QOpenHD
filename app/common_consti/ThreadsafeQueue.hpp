//
// Created by consti10 on 13.02.22.
//

#ifndef RV1126_OHD_SUSHI_THREADSAFEQUEUE_HPP
#define RV1126_OHD_SUSHI_THREADSAFEQUEUE_HPP

#include <queue>
#include <mutex>
#include <memory>
#include <semaphore.h>
#include "Logger.hpp"

// NOTE: the item is wrapped as std::shared_ptr
template<typename T>
class ThreadsafeQueue {
    std::queue<std::shared_ptr<T>> queue_;
    mutable std::mutex mutex_;
    // Moved out of public interface to prevent races between this
    // and pop().
    bool empty() const {
        return queue_.empty();
    }
public:
    ThreadsafeQueue() = default;
    ThreadsafeQueue(const ThreadsafeQueue<T> &) = delete ;
    ThreadsafeQueue& operator=(const ThreadsafeQueue<T> &) = delete ;
    ThreadsafeQueue(ThreadsafeQueue<T>&& other) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_ = std::move(other.queue_);
    }
    virtual ~ThreadsafeQueue() { }
    unsigned long size() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.size();
    }
    // returns the oldest item in the queue if available
    // nullptr otherwise
    std::shared_ptr<T> popIfAvailable() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return std::shared_ptr<T>(nullptr);
        }
        auto tmp = queue_.front();
        queue_.pop();
        return tmp;
    }
    // adds a new item to the queue
    void push(std::shared_ptr<T> item) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(item));
    }
    // returns a list of all buffers currently inside the queue and removes them from the queue
    // The first element in the returned list is the oldest element in the queue
    std::vector<std::shared_ptr<T>> getAllAndClear(){
        std::lock_guard<std::mutex> lock(mutex_);
        std::vector<std::shared_ptr<T>> ret;
        while (!queue_.empty()){
            ret.push_back(queue_.front());
            queue_.pop();
        }
        return ret;
    }
};


// Not sure how to call this, from drmprime example
// blocking, cannot put a new buffer in until the last buffer has been consumed
// after creation, you can put in a buffer immediately
// Then, you have to wait until this buffer has been consumed before you can put in the next buffer
template<typename T>
class ThreadsafeSingleBuffer{
public:
    ThreadsafeSingleBuffer(){
        sem_init(&q_sem_in, 0, 0);
        sem_init(&q_sem_out, 0, 0);
        // in the beginning, we can accept a new buffer immediately
        int ret=sem_post(&q_sem_out);
        /*if(ret!=0){
            MLOGD<<"Error\n";
        }else{
            MLOGD<<"Success\n";
        }*/
    }
    ~ThreadsafeSingleBuffer(){
        sem_destroy(&q_sem_in);
        sem_destroy(&q_sem_out);
    }
    // blocks until buffer is available
    // or terminate() has been called from another thread
    T getBuffer(){
        //MLOGD<<"A1\n";
        sem_wait(&q_sem_in);
        auto ret=q_buffer;
        q_buffer=NULL;
        sem_post(&q_sem_out);
        //MLOGD<<"A2\n";
        return ret;
    }
    // blocks until the current buffer has been consumed
    // and therefore can be updated to a new value
    void setBuffer(T newBuffer){
        //MLOGD<<"X1\n";
        sem_wait(&q_sem_out);
        //assert(message==NULL);
        q_buffer=newBuffer;
        sem_post(&q_sem_in);
        //MLOGD<<"X2\n";
    }
    // terminate, getBuffer() will return immediately
    void terminate(){
        q_terminate= true;
        sem_post(&q_sem_in);
    }
    // returns true when terminated
    bool terminated(){
        return q_terminate;
    }
    // be carefully, not synchronized at all
    T unsafeGetFrame(){
        return q_buffer;
    }
private:
    sem_t q_sem_in;
    sem_t q_sem_out;
    // terminate
    bool q_terminate=false;
    T q_buffer=NULL;
};


#endif //RV1126_OHD_SUSHI_THREADSAFEQUEUE_HPP