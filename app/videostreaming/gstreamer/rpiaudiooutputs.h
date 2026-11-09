#ifndef RPIAUDIOOUTPUTS_H
#define RPIAUDIOOUTPUTS_H

#include <istream>
#include <regex>
#include <string>
#include <vector>

// Use ALSA card IDs rather than indices: KMS can expose two HDMI cards
// before the headphone card, and USB devices can change the ordering again.
enum class RpiAudioOutput { Hdmi = 0, Headphones = 1 };

inline std::vector<std::string> rpi_audio_outputs(std::istream& cards, RpiAudioOutput output)
{
    const std::regex card_line(R"(^\s*\d+\s+\[\s*([A-Za-z0-9_-]+)\s*\]\s*:\s*(.*)$)");
    std::vector<std::string> outputs;
    std::string line;
    while (std::getline(cards, line)) {
        std::smatch match;
        if (!std::regex_match(line, match, card_line)) continue;
        const auto description = match[2].str();
        if (description.find("bcm2835") == std::string::npos &&
            description.find("vc4-hdmi") == std::string::npos) continue;
        const bool headphones = description.find("Headphones") != std::string::npos;
        const bool hdmi = description.find("HDMI") != std::string::npos ||
                          description.find("hdmi") != std::string::npos;
        if (output == RpiAudioOutput::Headphones ? !headphones : !hdmi) continue;
        outputs.push_back("plughw:CARD=" + match[1].str() + ",DEV=0");
    }
    return outputs;
}

#endif // RPIAUDIOOUTPUTS_H
