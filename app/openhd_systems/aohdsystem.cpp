#include "aohdsystem.h"

AOHDSystem::AOHDSystem(const bool is_air,QObject *parent)
    : QObject{parent},_is_air(is_air)
{

}

AOHDSystem &AOHDSystem::instanceAir()
{
    static AOHDSystem air(true);
    return air;
}

AOHDSystem &AOHDSystem::instanceGround()
{
    static AOHDSystem ground(false);
    return ground;
}
