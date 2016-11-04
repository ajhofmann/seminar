(h1 "Tag " (#:var tag))

(p "There have been " (#:var (string (length done)))
   " completed talks and " (#:var (string (length scheduled)))
   " scheduled talks tagged with " (b (#:var tag)) ".")

(h2 "Completed Talks")

(#:each t done
  (render-talk-brief (brief t)))

(h2 "Scheduled Talks")

(#:each t scheduled
  (render-talk-brief (brief t)))
