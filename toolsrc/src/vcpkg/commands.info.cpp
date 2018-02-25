#include "pch.h"

#include <vcpkg/base/system.h>
#include <vcpkg/commands.h>
#include <vcpkg/globalstate.h>
#include <vcpkg/help.h>
#include <vcpkg/paragraphs.h>
#include <vcpkg/sourceparagraph.h>
#include <vcpkg/vcpkglib.h>

#include <string>

namespace std
{
    std::string to_string(const vcpkg::Dependency& dep)
    {
        return vcpkg::to_string(dep);
    }
}

namespace vcpkg::Commands::Info
{

    template<class T>
    static std::string vector_to_string(const std::vector<T>& list, const std::string& separator)
    {
        std::string str;
        for(std::size_t i = 0; i < list.size(); ++i)
        {
            str += std::to_string(list[i]);
            // don't add the separator to the last element
            if(i != list.size()-1)
            {
                str += separator;
            }
        }
        return str;
    }

    static std::string vector_to_string(const std::vector<std::string>& list, const std::string& separator)
    {
        std::string str;
        for(std::size_t i = 0; i < list.size(); ++i)
        {
            str += list[i];
            // don't add the separator to the last element
            if(i != list.size()-1)
            {
                str += separator;
            }
        }
        return str;
    }


    static void do_print(const SourceParagraph& source_paragraph)
    {

        System::println(
            "%s\nVersion: %s\n%s\nMaintainer:%s", source_paragraph.name,
            source_paragraph.version, source_paragraph.description, source_paragraph.maintainer);
        System::println("Supports: %s", vector_to_string(source_paragraph.supports, ", "));
        System::println("Features: %s", vector_to_string(source_paragraph.default_features, ", "));
        System::println("Dependencies: %s", vector_to_string(source_paragraph.depends, ", "));

    }

    static void do_print_features(const std::string &name, const FeatureParagraph &feature_paragraph)
    {
        System::println("%s: %s", name + "[" + feature_paragraph.name + "]", feature_paragraph.description);
        System::println("Dependencies: %s", vector_to_string(feature_paragraph.depends, ", "));
    }

    static void do_print_reverse_dependencies(const std::vector<std::string>& dependees)
    {
        System::println("Reverse dependencies: %s", vector_to_string(dependees, ", "));
    }


    const CommandStructure COMMAND_STRUCTURE = {
        Strings::format(
            "The argument should be a substring to search for, or no argument to display all libraries.\n%s",
            Help::create_example_string("info png")),
        1,
        1,
        {{}, {}},
        nullptr,
    };

    std::vector<std::string> get_reverse_dependencies(const std::string& package, std::vector<std::unique_ptr<SourceControlFile>>& source_paragraphs)
    {
        std::vector<std::string> dependees;

        const auto& icontains = Strings::case_insensitive_ascii_equals;

        for (const auto& source_control_file : source_paragraphs)
        {
            auto &&sp = *source_control_file->core_paragraph;

            const bool is_package = icontains(sp.name, package);
            if(is_package)
            {
                // it's the package we are looking for, skip it
                continue;
            }
            // search the mandatory dependencies
            bool is_dependent = false;
            for(const auto& d : sp.depends)
            {
                is_dependent = icontains(d.name(), package);
                if(is_dependent)
                {
                    dependees.push_back(sp.name);
                    break;
                }
            }
            // if the current package depends on, we can skip the features
            if(is_dependent)
                continue;

            // check also the dependencies for each feature
            for (auto&& feature_paragraph : source_control_file->feature_paragraphs)
            {
                for(const auto& d : feature_paragraph->depends)
                {
                    is_dependent = icontains(d.name(), package);
                    if(is_dependent)
                    {
                        dependees.push_back(sp.name + "[" + feature_paragraph->name + "]");
                        continue;
                    }

                }
            }
        }
        return dependees;
    }

    void perform_and_exit(const VcpkgCmdArguments& args, const VcpkgPaths& paths)
    {
        const ParsedArguments options = args.parse_arguments(COMMAND_STRUCTURE);

        auto source_paragraphs = Paragraphs::load_all_ports(paths.get_filesystem(), paths.ports);

        const auto& icontains = Strings::case_insensitive_ascii_equals;

        // At this point there is 1 argument
        auto&& args_zero = args.command_arguments[0];
        for (const auto& source_control_file : source_paragraphs)
        {
            auto&& sp = *source_control_file->core_paragraph;

            const bool contains_name = icontains(sp.name, args_zero);

            if(!contains_name)
                continue;

            do_print(sp);

            for (auto&& feature_paragraph : source_control_file->feature_paragraphs)
            {
                do_print_features(sp.name, *feature_paragraph);
            }

            // print reverse dependencies
            auto dependees = get_reverse_dependencies(sp.name, source_paragraphs);
            do_print_reverse_dependencies(dependees);

            Checks::exit_success(VCPKG_LINE_INFO);
        }


        System::println(
            "\nIf your library is not listed, please open an issue at and/or consider making a pull request:\n"
            "    https://github.com/Microsoft/vcpkg/issues");

        Checks::exit_success(VCPKG_LINE_INFO);
    }
}
