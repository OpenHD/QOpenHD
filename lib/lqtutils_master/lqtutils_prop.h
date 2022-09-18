/**
 * MIT License
 *
 * Copyright (c) 2020 Luca Carlon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/

#ifndef LQTUTILS_PROP_H
#define LQTUTILS_PROP_H

// Define LQTUTILS_OMIT_ARG_FROM_SIGNAL to omit the argument from the change notification
// signals.
#ifdef LQTUTILS_OMIT_ARG_FROM_SIGNAL
#define LQTUTILS_EMIT_SIGNAL(name)
#define LQTUTILS_DECLARE_SIGNAL(type, name)
#else
#define LQTUTILS_EMIT_SIGNAL(name) name
#define LQTUTILS_DECLARE_SIGNAL(type, name) type name
#endif

// The EXPAND macro here is only needed for MSVC:
// https://stackoverflow.com/questions/5134523/msvc-doesnt-expand-va-args-correctly
#define EXPAND( x ) x
#define L_PROP_GET_MACRO(_1, _2, _3, _4, NAME,...) NAME

// QObject
// =======
#define L_RW_PROP(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP4, L_RW_PROP3, L_RW_PROP2)(__VA_ARGS__) )
#define L_RW_PROP_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP4_AS, L_RW_PROP3_AS, L_RW_PROP2_AS)(__VA_ARGS__) )
#define L_RW_PROP_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP4_CS, L_RW_PROP3_CS, L_RW_PROP2_CS)(__VA_ARGS__) )
#define L_RO_PROP(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP4, L_RO_PROP3, L_RO_PROP2)(__VA_ARGS__) )
#define L_RO_PROP_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP4_AS, L_RO_PROP3_AS, L_RO_PROP2_AS)(__VA_ARGS__) )
#define L_RO_PROP_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP4_CS, L_RO_PROP3_CS, L_RO_PROP2_CS)(__VA_ARGS__) )
// References
#define L_RW_PROP_REF(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP_REF4, L_RW_PROP_REF3, L_RW_PROP_REF2)(__VA_ARGS__) )
#define L_RW_PROP_REF_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP_REF4_AS, L_RW_PROP_REF3_AS, L_RW_PROP_REF2_AS)(__VA_ARGS__) )
#define L_RW_PROP_REF_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_PROP_REF4_CS, L_RW_PROP_REF3_CS, L_RW_PROP_REF2_CS)(__VA_ARGS__) )
#define L_RO_PROP_REF(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP_REF4, L_RO_PROP_REF3, L_RO_PROP_REF2)(__VA_ARGS__) )
#define L_RO_PROP_REF_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP_REF4_AS, L_RO_PROP_REF3_AS, L_RO_PROP_REF2_AS)(__VA_ARGS__) )
#define L_RO_PROP_REF_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_PROP_REF4_CS, L_RO_PROP_REF3_CS, L_RO_PROP_REF2_CS)(__VA_ARGS__) )

// A read-write prop both in C++ and in QML
// ========================================
#define _INT_DECL_L_RW_PROP(type, name, setter)                            \
    public:                                                                \
        type name() const { return m_##name ; }                            \
    Q_SIGNALS:                                                             \
        void name##Changed(LQTUTILS_DECLARE_SIGNAL(type, name));           \
    private:                                                               \
        Q_PROPERTY(type name READ name WRITE setter NOTIFY name##Changed)

#define L_RW_PROP_(type, name, setter)                                     \
    _INT_DECL_L_RW_PROP(type, name, setter)                                \
    public Q_SLOTS:                                                        \
        void setter(type name) {                                           \
            if (m_##name == name) return;                                  \
            m_##name = name;                                               \
            emit name##Changed(LQTUTILS_EMIT_SIGNAL(name));                \
        }                                                                  \
    private:

#define L_RW_PROP4(type, name, setter, def)                                \
    L_RW_PROP_(type, name, setter)                                         \
    type m_##name = def;

#define L_RW_PROP3(type, name, setter)                                     \
    L_RW_PROP_(type, name, setter)                                         \
    type m_##name;

// Autosetter
#define L_RW_PROP_AS_(type, name) L_RW_PROP_(type, name, set_##name)

#define L_RW_PROP3_AS(type, name, def)                                     \
    L_RW_PROP_AS_(type, name)                                              \
    type m_##name = def;

#define L_RW_PROP2_AS(type, name)                                          \
    L_RW_PROP_AS_(type, name)                                              \
    type m_##name;

// Custom setter
#define L_RW_PROP_CS_(type, name)                                          \
    _INT_DECL_L_RW_PROP(type, name, set_##name)

#define L_RW_PROP3_CS(type, name, def)                                     \
    L_RW_PROP_CS_(type, name)                                              \
    type m_##name = def;

#define L_RW_PROP2_CS(type, name)                                          \
    L_RW_PROP_CS_(type, name)                                              \
    type m_##name;

// A read-write prop from C++, but read-only from QML
// ==================================================
#define _INT_DECL_L_RO_PROP(type, name, setter)                  \
    public:                                                      \
        type name() const { return m_##name ; }                  \
    Q_SIGNALS:                                                   \
        void name##Changed(LQTUTILS_DECLARE_SIGNAL(type, name)); \
    private:                                                     \
        Q_PROPERTY(type name READ name NOTIFY name##Changed)     \

#define L_RO_PROP_(type, name, setter)                           \
    _INT_DECL_L_RO_PROP(type, name, set_##name)                  \
    public:                                                      \
        void setter(type name) {                                 \
            if (m_##name == name) return;                        \
            m_##name = name;                                     \
            emit name##Changed(LQTUTILS_EMIT_SIGNAL(name));      \
        }                                                        \
    private:

#define L_RO_PROP4(type, name, setter, def)                   \
    L_RO_PROP_(type, name, setter)                            \
    type m_##name = def;

#define L_RO_PROP3(type, name, setter)                        \
    L_RO_PROP_(type, name, setter)                            \
    type m_##name;

// Autosetter
#define L_RO_PROP_AS_(type, name) L_RO_PROP_(type, name, set_##name)

#define L_RO_PROP3_AS(type, name, def)                \
    L_RO_PROP_AS_(type, name)                         \
    type m_##name = def;

#define L_RO_PROP2_AS(type, name)                     \
    L_RO_PROP_AS_(type, name)                         \
    type m_##name;

// Custom setter
#define L_RO_PROP_CS_(type, name)                                          \
    _INT_DECL_L_RO_PROP(type, name, set_##name)

#define L_RO_PROP3_CS(type, name, def)                                     \
    L_RO_PROP_CS_(type, name)                                              \
    type m_##name = def;

#define L_RO_PROP2_CS(type, name)                                          \
    L_RO_PROP_CS_(type, name)                                              \
    type m_##name;

// For references
// ==============

// A read-write prop both in C++ and in QML
// ========================================
#define _INT_DECL_L_RW_PROP_REF(type, name, setter)                        \
    public:                                                                \
        type& name() { return m_##name ; }                                 \
    Q_SIGNALS:                                                             \
        void name##Changed(LQTUTILS_DECLARE_SIGNAL(type, name));           \
    private:                                                               \
        Q_PROPERTY(type name READ name WRITE setter NOTIFY name##Changed)

#define L_RW_PROP_REF_(type, name, setter)                                 \
    _INT_DECL_L_RW_PROP_REF(type, name, setter)                            \
    public Q_SLOTS:                                                        \
        void setter(type name) {                                           \
            if (m_##name == name) return;                                  \
            m_##name = name;                                               \
            emit name##Changed(LQTUTILS_EMIT_SIGNAL(name));                \
        }                                                                  \
    private:

#define L_RW_PROP_REF4(type, name, setter, def)                            \
    L_RW_PROP_REF_(type, name, setter)                                     \
    type m_##name = def;

#define L_RW_PROP_REF3(type, name, setter)                                 \
    L_RW_PROP_REF_(type, name, setter)                                     \
    type m_##name;

// Autosetter
#define L_RW_PROP_REF_AS_(type, name) L_RW_PROP_REF_(type, name, set_##name)

#define L_RW_PROP_REF3_AS(type, name, def)                            \
    L_RW_PROP_REF_AS_(type, name)                                     \
    type m_##name = def;

#define L_RW_PROP_REF2_AS(type, name)                                 \
    L_RW_PROP_REF_AS_(type, name)                                     \
    type m_##name;

// Custom setter
#define L_RW_PROP_REF_CS_(type, name)                                 \
    _INT_DECL_L_RW_PROP_REF(type, name, set_##name)

#define L_RW_PROP_REF3_CS(type, name, def)                            \
    L_RW_PROP_REF_CS_(type, name)                                     \
    type m_##name = def;

#define L_RW_PROP_REF2_CS(type, name)                                 \
    L_RW_PROP_REF_CS_(type, name)                                     \
    type m_##name;

// A read-write prop from C++, but read-only from QML
// ==================================================
#define _INT_DECL_L_RO_PROP_REF(type, name, setter)              \
    public:                                                      \
        type& name() { return m_##name ; }                       \
    Q_SIGNALS:                                                   \
        void name##Changed(LQTUTILS_DECLARE_SIGNAL(type, name)); \
    private:                                                     \
        Q_PROPERTY(type name READ name NOTIFY name##Changed)

#define L_RO_PROP_REF_(type, name, setter)                       \
    _INT_DECL_L_RO_PROP_REF(type, name, setter)                  \
    public Q_SLOTS:                                              \
        void setter(type name) {                                 \
            if (m_##name == name) return;                        \
            m_##name = name;                                     \
            emit name##Changed(LQTUTILS_EMIT_SIGNAL(name));      \
        }                                                        \
    private:

#define L_RO_PROP_REF4(type, name, setter, def)               \
    L_RO_PROP_REF_(type, name, setter)                        \
    type m_##name = def;

#define L_RO_PROP_REF3(type, name, setter)                    \
    L_RO_PROP_REF_(type, name, setter)                        \
    type m_##name;

// Autosetter
#define L_RO_PROP_REF_AS_(type, name) L_RO_PROP_REF_(type, name, set_##name)

#define L_RO_PROP_REF3_AS(type, name, def)            \
    L_RO_PROP_REF_AS_(type, name)                     \
    type m_##name = def;

#define L_RO_PROP_REF2_AS(type, name)                 \
    L_RO_PROP_REF_AS_(type, name)                     \
    type m_##name;

// Custom setter
#define L_RO_PROP_REF_CS_(type, name)                                 \
    _INT_DECL_L_RO_PROP_REF(type, name, set_##name)                   \

#define L_RO_PROP_REF3_CS(type, name, def)                            \
    L_RO_PROP_REF_CS_(type, name)                                     \
    type m_##name = def;

#define L_RO_PROP_REF2_CS(type, name)                                 \
    L_RO_PROP_REF_CS_(type, name)                                     \
    type m_##name;

// Convenience macros to speed up a QObject subclass.
#define L_BEGIN_CLASS(name)                           \
    class name : public QObject                       \
    {                                                 \
        Q_OBJECT                                      \
    public:                                           \
        Q_INVOKABLE name(QObject* parent = nullptr) : \
            QObject(parent) {}                        \
    private:

#define L_END_CLASS };

// Gadget
// ======

#define L_RW_GPROP(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_GPROP4, L_RW_GPROP3, L_RW_GPROP2)(__VA_ARGS__) )
#define L_RW_GPROP_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_GPROP4_AS, L_RW_GPROP3_AS, L_RW_GPROP2_AS)(__VA_ARGS__) )
#define L_RW_GPROP_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RW_GPROP4_CS, L_RW_GPROP3_CS, L_RW_GPROP2_CS)(__VA_ARGS__) )
#define L_RO_GPROP(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_GPROP4, L_RO_GPROP3, L_RO_GPROP2)(__VA_ARGS__) )
#define L_RO_GPROP_AS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_GPROP4_AS, L_RO_GPROP3_AS, L_RO_GPROP2_AS)(__VA_ARGS__) )
#define L_RO_GPROP_CS(...) \
    EXPAND( L_PROP_GET_MACRO(__VA_ARGS__, L_RO_GPROP4_CS, L_RO_GPROP3_CS, L_RO_GPROP2_CS)(__VA_ARGS__) )

#define _INT_DECL_GADGET_PROP_GETTER(type, name)                           \
    public:                                                                \
        type name() const { return m_##name ; }

// A read-write prop both in C++ and in QML
// ========================================
#define L_RW_GPROP_(type, name, setter)                                    \
    _INT_DECL_GADGET_PROP_GETTER(type, name)                               \
    private:                                                               \
        Q_PROPERTY(type name READ name WRITE setter)                       \
    public:                                                                \
        void setter(type name) {                                           \
            m_##name = name;                                               \
        }                                                                  \
    private:

#define L_RW_GPROP4(type, name, setter, def)                                \
    L_RW_GPROP_(type, name, setter)                                         \
    type m_##name = def;

#define L_RW_GPROP3(type, name, setter)                                     \
    L_RW_GPROP_(type, name, setter)                                         \
    type m_##name;

// Autosetter
#define L_RW_GPROP_AS_(type, name) L_RW_GPROP_(type, name, set_##name)

#define L_RW_GPROP3_AS(type, name, def)                        \
    L_RW_GPROP_AS_(type, name)                                 \
    type m_##name = def;

#define L_RW_GPROP2_AS(type, name)                             \
    L_RW_GPROP_AS_(type, name)                                 \
    type m_##name;

// Custom setter
#define L_RW_GPROP_CS_(type, name)                             \
    _INT_DECL_GADGET_PROP_GETTER(type, name)                   \
    private:                                                   \
        Q_PROPERTY(type name READ name)

#define L_RW_GPROP3_CS(type, name, def)                        \
    L_RW_GPROP_CS_(type, name)                                 \
    type m_##name = def;

#define L_RW_GPROP2_CS(type, name)                             \
    L_RW_GPROP_CS_(type, name)                                 \
    type m_##name;

// A read-write prop from C++, but read-only from QML
// ==================================================
#define L_RO_GPROP_(type, name, setter)                       \
    _INT_DECL_GADGET_PROP_GETTER(type, name)                  \
    private:                                                  \
        Q_PROPERTY(type name READ name)                       \
    public:                                                   \
        void setter(type name) {                              \
            m_##name = name;                                  \
        }                                                     \
    private:

#define L_RO_GPROP4(type, name, setter, def)                  \
    L_RO_GPROP_(type, name, setter)                           \
    type m_##name = def;

#define L_RO_GPROP3(type, name, setter)                       \
    L_RO_GPROP_(type, name, setter)                           \
    type m_##name;

// Autosetter
#define L_RO_GPROP_AS_(type, name) L_RO_GPROP_(type, name, set_##name)

#define L_RO_GPROP3_AS(type, name, def)                       \
    L_RO_GPROP_AS_(type, name)                                \
    type m_##name = def;

#define L_RO_GPROP2_AS(type, name)                            \
    L_RO_GPROP_AS_(type, name)                                \
    type m_##name;

// Custom setter
#define L_RO_GPROP_CS_(type, name)                             \
    _INT_DECL_GADGET_PROP_GETTER(type, name)                   \
    private:                                                   \
        Q_PROPERTY(type name READ name)

#define L_RO_GPROP3_CS(type, name, def)                        \
    L_RO_GPROP_CS_(type, name)                                 \
    type m_##name = def;

#define L_RO_GPROP2_CS(type, name)                             \
    L_RO_GPROP_CS_(type, name)                                 \
    type m_##name;

// Convenience macros to speed up a gadget subclass.
#define L_BEGIN_GADGET(name)                          \
    class name                                        \
    {                                                 \
        Q_GADGET                                      \
    public:                                           \
        Q_INVOKABLE name() {}                         \
    private:


#define L_END_GADGET };

#endif // LQTUTILS_PROP_H
