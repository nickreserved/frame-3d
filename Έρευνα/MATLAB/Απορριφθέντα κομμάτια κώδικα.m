% Κάθε xml σχόλιο-κόμβος (COMMENT_NODE) και κάθε κείμενου κενού χαρακτήρα
% (whitespace TEXT_NODE) του xml απαλείφεται για να μας διευκολύνει στη λεκτική
% ανάλυση του XML (parsing).
% Η συναρτηση είναι αναδρομική. Κάθε node την καλεί για κάθε έναν node-παιδί.
% in: node Ένας xml node.
function parseWhitespaceStrip(node)
  children = node.getChildNodes;
  child = children.getFirstChild;
  while ~isempty(child)
      if (child.hasChildNodes)
        parseWhitespaceStrip(child);
        child = child.getNextSibling;
      elseif (child.getNodeType == 3 && ~length(strtrim(child.getNodeValue)) || child.getNodeType == 8)
        child1 = child;
        child = child.getNextSibling;
        node.removeChild(child1);
      else
        child = child.getNextSibling;
      endif
  end
endfunction