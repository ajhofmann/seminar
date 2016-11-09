#!/usr/bin/env julia

using JSON
using English
using DataStructures

include("build_help.jl")

try
    mkdir("public/archive")
end

human(d::Date) = Dates.format(d, "E U d, YYYY")
human(d) = human(Date(d))

identifier(t) = t[:identifier]

function relatedto(t)
    relevant = filter(x -> t in x[:tags], result)
    top = [(tag, count(x -> tag in x[:tags], relevant) /
                 (tagpopularity[tag] + 2))
           for tag in tags if tag != t]
    filter!(x -> x[2] > 0, top)
    sort!(top, by=x -> -x[2])
    take(top, 5)
end

function write_summary(t)
    generate_page(merge(Dict(
        :title => t[:topic],
        :pagetype => "archive",
        :mathjaxplease => true
    ), t), "archive/$(identifier(t))")
end

iscompleted(t) = Date(t[:date]) < Dates.today()
function valuate(talk)
    sum([1,
         talk[:location] != "Online",
         iscompleted(talk),
         haskey(talk, :abstract),
         haskey(talk, :summary)])
end

summarize(t) = "Talk by $(t[:speaker])."

function brief(t)
    if haskey(t, :type) && t[:type] == "reference"
        Dict(:title => t[:title],
             :url => "document/$(t[:id])",
             :summary => join(flatten([
                ["This is a reference document on $(t[:title])",
                 "by $(ItemList(t[:authors]))."],
                (haskey(t, :subsetof) && !isempty(t[:subsetof]) ?
                    ["It covers a subset of the material of",
                     "$(ItemList(t[:subsetof], Disjunction()))."] :
                    [])
             ]), " "))
    else
        Dict(:title => t[:topic],
             :url => "/seminar/archive/$(identifier(t))",
             :summary => summarize(t))
    end
end

result = JSON.parsefile("schedule.json", dicttype=Dict{Symbol,Any})
sort!(result, by=x -> x[:time])
map!(result) do d
    d[:date], d[:time] = split(d[:time], 'T')
    d
end
dates = unique(map(x -> x[:date], result))

tags = Set{String}()
talks = []

for d in dates
    if Date(d) < Dates.today()
        for t in filter(x -> x[:date] == d, result)
            write_summary(t)
            push!(talks, brief(t))
        end
    end
end

# tag collection
talkdict = Dict{String,Any}()
tagpopularity = DefaultDict(String, Int, 0)
for t in result
    talkdict[identifier(t)] = t
    union!(tags, t[:tags])
    value = valuate(t)
    for tag in t[:tags]
        tagpopularity[tag] += value
    end
end

# suggestion gathering
include("topic-suggestions.jl")

# documents
include("documents.jl")
tags = sort(collect(tags), by=t -> -tagpopularity[t])

generate_page(Dict(
    :title => "Archived Talks",
    :pagetype => "archived-talks",
    :talks => talks,
    :mathjaxplease => true), "archive")

generate_page(Dict(
    :title => "Mathematics Student Seminars",
    :pagetype => "home",
    :dates => dates,
    :talks => result,
    :github => "$GITHUB/lisp/home.lsp",
    :mathjaxplease => true), "")

generate_page(Dict(
    :title => "List of Tags",
    :pagetype => "tags",
    :tags => tags), "tags")

try mkdir("public/tag") end
for t in tags
    active_set = filter(x -> t in x[:tags], result)
    generate_page(Dict(
        :title => "Tag $t",
        :tag => t,
        :pagetype => "tag",
        :brief => brief,
        :related => relatedto(t),
        :talkdict => talkdict,
        :done => filter(iscompleted, active_set),
        :scheduled => filter(x -> !iscompleted(x), active_set),
        :documents => docs_bytag[t],
        :mathjaxplease => true,
        :suggestions => bytag[t]), "tag/$t")
end

generate_page(Dict(
    :title => "Potential Topics",
    :pagetype => "suggested-topics",
    :talkdict => talkdict,
    :suggestions => suggestions,
    :mathjaxplease => true,
    :github => "$GITHUB/lisp/suggested-topics.lsp"), "potential-topics")

for file in readdir("static")
    println("Copying file $file...")
    cp("static/$file", "public/$file"; remove_destination=true)
end
