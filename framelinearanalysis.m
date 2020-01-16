% Η κύρια δομή δεδομένων του προγράμματος είναι προσβάσιμη από παντού
global data;

% =================================================================== XML PARSER


% Το Octave απαιτεί τη βιβλιοθήκη Apache Xerces για να φορτώσει, αποθηκεύσει
% και κάνει λεκτική ανάλυση, αρχεία xml.
% Η βιβλιοθήκη δεν υπάρχει στο Octave. Ο χρήστης πρέπει να την κατεβάσει.
javaaddpath("xercesImpl-2.12.0-sp1.jar");
javaaddpath("xml-apis-ext-1.3.04.jar");
% Το Octave απαιτεί το io πακέτο για να φορτώσει, αποθηκεύσει και κάνει λεκτική
% ανάλυση, αρχεία xml.
% Για την εγκατάστασή του εκτελούμε την εντολή `pkg install -forge io`
pkg load io;

% Ελέγχει αν ένα xml element έχει το όνομα που θέλουμε.
% in: node: xml element για έλεγχο
% in: name: Το όνομα που θέλουμε να έχει το xml element
% error: Αν δεν έχει το όνομα που θέλουμε
function parseCheckElementName(node, name)
	if ~strcmp(node.getNodeName, name)
		error(["Αναμένονταν ", name, " element, βρέθηκε ", node.getNodeName]);
	endif;
endfunction

% Το κείμενο είναι έγκυρο xml όνομα
% in: str Το κείμενο
% out: is Το κείμενο είναι έγκυρο xml όνομα, κατάλληλο για @id
function is = isXmlName(str)
	is = ~isempty(regexp(str, '^[A-Za-z_Α-Ωα-ω’-Ώά-ώϊΐϋΐς][\w-.]*$'));
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα material
% in: node: Το xml element του υλικού.
% out: material: Octave δομή υλικού.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function material = parseMaterial(node)
	parseCheckElementName(node, "material");
	material.id = node.getAttribute("id"); % Το material@id είναι προαιρετικό
	% Σταθερά του Young
	material.E = str2num(node.getAttribute("E"));
	if (length(material.E) ~= 1 || material.E <= 0)
		error(["material με μη έγκυρο @E=", num2str(material.E)]);
	endif;
	% Λόγος Poisson
	v = str2num(node.getAttribute("v"));
	if (length(v))
		if (length(v) ~= 1 || v <= 0 || v > 0.5)
			error(["material με μη έγκυρο @v=", num2str(v)]);
		endif;
		material.v = v;
	endif
endfunction

% Λεκτική ανάλυση ενός xml element "O"
% in: node: Το xml element της διατομής.
% out: section: Octave δομή διατομής.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function section = parseFrameSectionO(node)
	section.diameter = str2num(node.getAttribute("diameter"));
	if (length(section.diameter) == 1)
		if (section.diameter < 0)
			error(["Πρέπει frame_section@diameter > 0, δηλαδή ", num2str(section.diameter), " > 0"]);
		endif;
	elseif (length(section.diameter) == 2)
		if (section.diameter(1) <= section.diameter(2) || section.diameter(2) < 0)
			error(["Πρέπει 0 <= frame_section@diameter(2) < frame_section@diameter(1), δηλαδή 0 < ", ...
					num2str(section.diameter(2)), " < ", num2str(section.diameter(1))]);
		endif;
	else
		error(["Ο αριθμός διαμέτρων μπορεί να είναι ένας (συμπαγής) ή δύο (εξωτερικός - εσωτερικός). Βρέθηκαν ", ...
				num2str(length(section.diameter))]);
	endif
endfunction

% Λεκτική ανάλυση ενός xml element "generic"
% in: node: Το xml element της διατομής.
% out: section: Octave δομή διατομής.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function section = parseFrameSectionGeneric(node)
	A = str2num(node.getAttribute("A"));
	if (length(A))
		if (length(A) > 1 || A <= 0) error(["Πρέπει generic@Iy > 0, δηλαδή ", num2str(Iy), " > 0"]); endif
		section.A = A;
	endif
	Iy = str2num(node.getAttribute("Iy"));
	if (length(Iy))
		if (length(Iy) > 1 || Iy <= 0) error(["Πρέπει generic@Iy > 0, δηλαδή ", num2str(Iy), " > 0"]); endif
		section.Iy = Iy;
	endif
	Iz = str2num(node.getAttribute("Iz"));
	if (length(Iz))
		if (length(Iz) > 1 || Iz <= 0) error(["Πρέπει generic@Iz > 0, δηλαδή ", num2str(Iz), " > 0"]); endif
		section.Iz = Iz;
	endif
	It = str2num(node.getAttribute("It"));
	if (length(It))
		if (length(It) > 1 || It <= 0) error(["Πρέπει generic@It > 0, δηλαδή ", num2str(It), " > 0"]); endif
		section.It = It;
	endif
	Cs = str2num(node.getAttribute("Cs"));
	if (length(Cs))
		if (length(Cs) > 1 || Cs <= 0) error(["Πρέπει generic@Cs > 0, δηλαδή ", num2str(Cs), " > 0"]); endif
		section.Cs = Cs;
	endif
	It_S = str2num(node.getAttribute("It_S"));
	if (length(It_S))
		if (length(It_S) > 1 || It_S <= 0) error(["Πρέπει generic@It_S > 0, δηλαδή ", num2str(It_S), " > 0"]); endif
		section.It_S = It_S;
	endif
	ay = str2num(node.getAttribute("ay"));
	if (length(ay))
		if (length(ay) > 1 || ay < 1) error(["Πρέπει generic@ay > 1, δηλαδή ", num2str(ay), " > 1"]); endif
		section.ay = ay;
	endif
	az = str2num(node.getAttribute("az"));
	if (length(az))
		if (length(az) > 1 || az < 1) error(["Πρέπει generic@az > 1, δηλαδή ", num2str(az), " > 1"]); endif
		section.az = az;
	endif
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα frame_section
% in: node: Το xml element της διατομής.
% out: section: Octave δομή διατομής.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function section = parseFrameSection(node)
	type = node.getNodeName;
	switch(type)
		case "O" 				section = parseFrameSectionO(node);
		case "generic"	section = parseFrameSectionGeneric(node);
		otherwise error(['Μη υποστηριζόμενος τύπος διατομής ', type]);
	endswitch;
	section.type = type;
	section.id = node.getAttribute("id"); % Το section@id είναι προαιρετικό
endfunction

% Συντεταγμένες ενός σημείου που διαβάζονται από κείμενο χωρισμένο με κενά
% in: str: Κείμενο που περιέχει συντεταγμένες χωρισμένες με κενά.
% out: coords: Οι συντεταγμένες του σημείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function coords = parseCoords(str)
	if (strcmp(str, "+x")) coords = [1, 0, 0];
	elseif (strcmp(str, "+y")) coords = [0, 1, 0];
	elseif (strcmp(str, "+z")) coords = [0, 0, 1];
	elseif (strcmp(str, "-x")) coords = [-1, 0, 0];
	elseif (strcmp(str, "-y")) coords = [0, -1, 0];
	elseif (strcmp(str, "-z")) coords = [0, 0, -1];
	else
		coords = str2num(str);
		if (length(coords) ~= 2 && length(coords) ~= 3)
			error(["Οι συντεταγμένες πρέπει να είναι 2 ή 3 και βρέθηκαν ", num2str(length(coords))]);
		elseif (length(coords) == 2) coords(3) = 0;    % Προσθήκη 3ης συντεταγμένης
		endif
	endif
endfunction

% Τοπικό σύστημα συντεταγμένων που διαβάζεται από κείμενο χωρισμένο με κενά
% in: str: Κείμενο που περιέχει συντεταγμένες αξόνων του συστήματος χωρισμένες με κενά.
% out: lcs: Ο πίνακας του τοπικού συστήματος συντεταγμένων ή empty αν δεν υπάρχει.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function lcs = parseCoordinateSystem(str)
	lcs = str2num(str);
	if (length(lcs) == 6)    % 3d τοπικό σύστημα συντεταγμένων
		x = lcs(1:3);
		y = lcs(4:6);
		n = norm(x);
		if (~n) error("Μηδενικό διάνυσμα άξονα x σε τοπικό σύστημα συντεταγμένων"); endif
		x /= n;
		n = norm(y);
		if (~n) error("Μηδενικό διάνυσμα άξονα y σε τοπικό σύστημα συντεταγμένων"); endif
		y /= n;
		z = cross(x, y);
		n = norm(z);
		if (n < 0.02)
			error(["Το διάνυσμα του άξονα y πρέπει να έχει γωνία τουλάχιστον 1.145° με τον άξονα x σε τοπικό σύστημα συντεταγμένων: y=", ...
								num2str(y), " θxy=", num2str(asin(n * 180 / pi)), "°"]);
		endif
		z /= n;
		y = cross(z, x);
		lcs = [x; y; z];
	elseif (length(lcs) == 2) % 2d τοπικό σύστημα συντεταγμένων που θα γίνει 3d
		n = norm(lcs);
		if (~n) error("Μηδενικό διάνυσμα άξονα x σε τοπικό σύστημα συντεταγμένων"); endif
		lcs /= n;
		lcs(3) = 0;
		z = [0, 0, 1];
		lcs = [lcs; cross(z, lcs); z];
	else
		error(["Ένα σύστημα συντεταγμένων ορίζεται από 6 ή 2 συνιστώσες και βρέθηκαν ", ...
				num2str(length(lcs))]);
	endif
endfunction

% Λεκτική ανάλυση ενός xml element που περιέχει φορτιο (π.χ. force ή moment)
% in: node: Το xml element του στοιχείου.
% out: load: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function load = parseLoad(node)
	% Είναι δύναμη ή ροπή;
	str = node.getNodeName;
	switch(str)
		case "force" load.force = true;
		case "moment" load.force = false;
		otherwise error(["Το φορτίο μπορεί να είναι ή force ή moment και βρέθηκε: ", str]);
	endswitch
	load.id = node.getAttribute("id"); % Το node@id είναι προαιρετικό
	load.coords = parseCoords(node.getAttribute("direction"));	% Κατεύθυνση φορτίου
	n = norm(load.coords);
	if (~n) error("Μηδενικό διάνυσμα κατεύθυνσης φορτίου"); endif
	% Το μέτρο του φορτίου (προαιρετικό)
	% Η λογική είναι να δώσουμε μια κατεύθυνση στο φορτίο τέτοια ώστε να μας βολεύουν τα νουμερα και
	% ακολούθως να δώσουμε το μέτρο του φορτίου. Αν παραλείπεται, η κατεύθυνση του φορτίου περιλαμβάνει
	% το μέτρο
	if (node.hasAttribute("magnitude"))
		magnitude = str2num(node.getAttribute("magnitude"));
		switch(length(magnitude))
			case 1
				load.coords *= magnitude / n;
			case 2	% Κατανεμημένο φορτίο με κατανομή τραπεζίου
				load.coords /= n;
				load.magnitude = magnitude;
			otherwise
				error(["Το μέγεθος φορτίου είναι προαιρετικό, και βρέθηκε μη έγκυρο: ", num2str(magnitude)]);
		endswitch
	endif
	% Το φορτίο εφαρμόζεται σε σύστημα συντεταγμένων τοπικό ή καθολικό
	% Αφορά μόνο μέλη (στοιχεία). Σε κόμβους αγνοείται.
	load.lcs = true;	% default τιμή
	if (node.hasAttribute("coordinate_system"))
		str = node.getAttribute("coordinate_system");
		switch(str)
			case "global"
				load.lcs = false;
			case "local"
			otherwise
				error(["το σύστημα συντεταγμένων του φορτίου είναι ή global ή local, και βρέθηκε: ", str]);
		endswitch
	endif
endfunction

% Επιστρέφει το index ενός στοιχείου από τις φορτωμένες ομάδες στοιχείων
% in: m: Το όνομα (@id) ή το index από ένα στοιχείο μιας ομάδας στοιχείων.
% in: what: Το είδος της ομάδας στοιχείων π.χ. "section" ή "material" ή "load" ή "node".
% out: idx: Το index του στοιχείου στην ομάδα στοιχείων.
function idx = getItemIndexFromData(m, what)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	whats = [what, "s"];
	if (isnumeric(m)) idxd = m; state = true;
	else [idxd, state] = str2num(m);
	endif
	idx = uint32(idxd);
	if (~state)
		if (isfield(data.map.(whats), m))
			idx = data.map.(whats).(m);
		else
			error(["Εσφαλμένη αναφορά σε όνομα ", what, ": ", m]);
		endif
	elseif (length(idx) ~= 1 || idx > length(data.(whats)) || idx != idxd)
		error(["Εσφαλμένη αναφορά σε index ", what, ": ", num2str(m)]);
	endif
endfunction

% Επιστρέφει ένα στοιχείο από τις φορτωμένες ομάδες στοιχείων
% in: m: Το όνομα (@id) ή το index από ένα στοιχείο μιας ομάδας στοιχείων.
% in: what: Το είδος της ομάδας στοιχείων π.χ. "section" ή "material" ή "load" ή "node".
% out: item: Το στοιχείο από την ομάδα στοιχείων.
function item = getItemFromData(m, what)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	item = data.([what, "s"]){getItemIndexFromData(m, what)};
endfunction

% Επιστρέφει λίστα με τα indices στοιχείων από τις φορτωμένες ομάδες στοιχείων
% in: m: Τα ονόματα (@id) ή τα indices από ένα αριθμό στοιχείων μιας ομάδας στοιχείων.
% in: what: Το είδος της ομάδας στοιχείων π.χ. "section" ή "material" ή "load" ή "node".
% out: idx: Λίστα με τα indices των στοιχείων στην ομάδα στοιχείων.
function idx = getItemsIndicesFromData(m, what)
	n = strsplit(m, " ");
	idx = [];
	for i = n
		idx = [idx, getItemIndexFromData(i{1}, what)];
	endfor
endfunction

% Επιστρέφει τα στοιχεία από τις φορτωμένες ομάδες στοιχείων
% in: m: Τα ονόματα (@id) ή τα indices από ένα αριθμό στοιχείων μιας ομάδας στοιχείων.
% in: what: Το είδος της ομάδας στοιχείων π.χ. "section" ή "material" ή "load" ή "node".
% out: items: Λίστα με τα στοιχεία στην ομάδα στοιχείων.
function items = getItemsFromData(m, what)
	n = strsplit(m, " ");
	items = {};
	for i = n
		items{length(items) + 1} = getItemFromData(i{1}, what);
	endfor
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα node
% in: node: Το xml element του κόμβου.
% out: nodE: Octave δομή κόμβου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function nodE = parseNode(node)
	global data;
	parseCheckElementName(node, "node");
	nodE.id = node.getAttribute("id");			% Το node@id είναι προαιρετικό
	% Συντεταγμένες κόμβου. Ορίζονται ή αντιγράφονται από άλλον.
	% Αντιγράφονται από άλλον όταν έχουμε π.χ. εσωτερική ελευθέρωση.
	b1 = node.hasAttribute("coords"); b2 = node.hasAttribute("clone_coords");
	if (b1 && b2 || ~b1 && ~b2)
		error("Ο node πρέπει να έχει ακριβώς ένα από @coords και @clone_coords");
	end
	if (node.hasAttribute("coords"))
		nodE.coords = parseCoords(node.getAttribute("coords"));	% Συντεταγμένες κόμβου
	else
		nodE.coords = getItemFromData(node.getAttribute("clone_coords"), "node").coords;
	endif
	% Επικόμβια φορτία
	if (node.hasAttribute("loads"))
		loads = getItemsIndicesFromData(node.getAttribute("loads"), "load");
		for i = loads
			if (isfield(data.loads{i}, "magnitude"))
				error(["Αποδόθηκε το τραπεζίως κατανεμημένο φορτίο ", num2str(i), " σε κόμβο"]);
			endif
		endfor
	else loads = [];
	endif
	if (node.hasAttribute("clone_loads"))
		loads = [loads, getItemFromData(node.getAttribute("clone_loads"), "node").loads];
	endif
	if (length(loads)) nodE.loads = loads; endif;
endfunction

% Κοινός κώδικας λεκτικής ανάλυσης πρισματικών στοιχείων
% Δες parseBar() και parseBeam()
function element = parsePrismaticCommon(node)
	element.material = getItemIndexFromData(node.getAttribute("material"), "material");
	element.section = getItemIndexFromData(node.getAttribute("section"), "frame_section");
	element.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (length(element.nodes) ~= 2)
		error(["Η δοκός έχει 2 κόμβους, βρέθηκαν ", num2str(length(element.nodes))]);
	endif
	if (node.hasAttribute("initial_loads"))
		element.initial_load = str2num(node.getAttribute("initial_loads"));
	endif
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα bar
% in: node: Το xml element του στοιχείου.
% out: element: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function element = parseBar(node)
	element = parsePrismaticCommon(node);
	element.type = uint16(0);	% bar type
	% Έλεγχος των προφορτίσεων να είναι μία τιμή μόνο
	if (isfield(element, "initial_load"))
		if (length(element.initial_load) ~= 1)
			error(["Η ράβδος έχει μια τιμή για προφόρτιση, βρέθηκαν ", ...
					num2str(length(element.initial_load))]);
		endif
	endif
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα beam
% in: node: Το xml element του στοιχείου.
% out: element: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function element = parseBeam(node)
	element = parsePrismaticCommon(node);
	element.type = uint16(3);	% beam type
	% Έλεγχος των προφορτίσεων
	if (isfield(element, "initial_load"))
		switch(length(element.initial_load))
			case 3 element.initial_load = [element.initial_load(1:2) 0 0 0 element.initial_load(3) 0];
			case 6 element.initial_load(7) = 0;
			case 7
			otherwise
				error(["Η δοκός μπορεί να έχει 3, 6 ή 7 τιμές για προφόρτιση, βρέθηκαν ", ...
						num2str(length(element.initial_load))]);
		endswitch
	endif
	% Διεύθυνση z
	if (node.hasAttribute("z_axis"))
		element.axisZ = parseCoords(node.getAttribute("z_axis"));
		n = norm(element.axisZ);
		if (~n) error("Η διεύθυνση beam@z_axis βρέθηκε μηδενική"); endif
		element.axisZ /= n;
	endif
	% Κατανεμημένα φορτία
	if (node.hasAttribute("distributed_loads"))
		element.distributed_loads = getItemsIndicesFromData(node.getAttribute("distributed_loads"), "load");
	endif
	% Στρέβλωση
	element.warp = false;
	if (node.hasAttribute("warp"))
		w = node.getAttribute("warp");
		switch(w)
			case "yes" element.warp = true;
			case "no"
			otherwise error(["Η δοκός αν έχει @warp πρέπει να είναι yes ή no, βρέθηκε: ", w]);
		endswitch
	endif
endfunction

% Λεκτική ανάλυση ενός xml element με όνομα spring
% in: node: Το xml element του στοιχείου.
% out: element: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function element = parseSpring(node)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	type = node.getAttribute("type");
	switch(type)
		case, "linear"
			element.type = uint16(1);		% linear spring type
		case "torsion"
			element.type = uint16(2);		% torsion spring type
		otherwise
			error(["Το ελατήριο πρέπει έχει @type linear ή torsion, βρέθηκε ", type]);
	endswitch
	element.K = str2num(node.getAttribute("K"));
	if (length(element.K) ~= 1)
		error(["Το ελατήριο έχει μια σταθερά Κ, βρέθηκαν ", num2str(length(element.K))]);
	endif
	element.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (length(element.nodes) ~= 1 && length(element.nodes) ~= 2)
		error(["Το ελατήριο έχει 1 ή 2 κόμβους, βρέθηκαν ", num2str(length(element.nodes))]);
	endif
	% @direction: Αν υπάρχει ή είναι στροφικό ελατήριο ή είναι γραμμικό και οι 2 κόμβοι ταυτίζονται.
	% ειδάλλως η κατεύθυνση είναι από τον πρώτο στο δεύτερο κόμβο.
	if (length(element.nodes) == 2)
		element.direction = data.nodes(element.nodes(2)).coords - data.nodes(element.nodes(1)).coords;
		n = norm(element.direction);
	endif
	if (node.hasAttribute("direction") || length(element.nodes) == 1 || element.type == 2 || ~n)
		element.direction = parseCoords(node.getAttribute("direction"));
		n = norm(element.direction);
		if (~n) error("Μηδενικό διάνυσμα κατεύθυνσης ελατηρίου"); endif
	endif
	element.direction /= n;	% μοναδιαίο
	if (node.hasAttribute("initial_loads"))
		element.initial_load = str2num(node.getAttribute("initial_loads"));
		if (length(element.initial_load) ~= 1)
			error(["Το ελατήριο έχει μια τιμή για προφόρτιση, βρέθηκαν ", ...
				num2str(length(element.initial_load))]);
		endif
	endif
endfunction

% Λεκτική ανάλυση ενός xml element που είναι στοιχείο πεπερασμένων στοιχείων
% in: node: Το xml element του στοιχείου.
% out: element: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function element = parseElement(node)
	% Επεξεργασία στοιχείου με βάση τον τύπο του
	switch(node.getNodeName)
		case "bar"		element = parseBar(node);
		case "spring"	element = parseSpring(node);
		case "beam"		element = parseBeam(node);
		otherwise			error(["Μη υποστηριζόμενος τύπος στοιχείου: ", node.getNodeName]);
	endswitch
	element.id = node.getAttribute("id"); % Το node@id είναι προαιρετικό
endfunction

% Λεκτική ανάλυση ενός xml attribute που είναι δέσμευση ενός και μόνο DoF
% Μπορεί να είναι "yes", "no", αριθμός ή να παραλείπεται.
% Αν ο DoF είναι δεσμευμένος, στη λίστα restraint.dofs προσθέτει το ζευγάρι
% index του DoF και την τιμή της δέσμευσης.
% in: node: Το xml element του στοιχείου.
% in: name: Το όνομα του xml attribute του DoF.
% in/out: restraint: Το αντικείμενο της δέσμευσης.
% in: index: Το index του DoF στον κόμβο. π.χ. ο disp_y είναι 2.
function restraint = parseRestraintDOF(node, name, restraint, index)
	if (~node.hasAttribute(name)) return; endif
	c = node.getAttribute(name);
	switch(c)
		case "no" return;
		case "yes" a = 0;
		otherwise
			a = str2num(c);
			if (length(a) ~= 1) error(["Μη αποδεκτή τιμή δέσμευσης ", name, ": ", c]); endif
	endswitch
	% Επιλέγεται αυτό το ανάστροφο format γιατί η for απαριθμεί στήλες(!) αντί για γραμμές
	restraint.dofs = [restraint.dofs, [index; a]];
endfunction

% Λεκτική ανάλυση ενός xml element που είναι καταναγκασμός (στήριξη)
% in: node: Το xml element του στοιχείου.
% out: restraint: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function restraint = parseRestraint(node)
	parseCheckElementName(node, "restraint");
	restraint.id = node.getAttribute("id"); % Το node@id είναι προαιρετικό
	restraint.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (~length(restraint.nodes)) error("Η δέσμευση πρέπει να έχει τουλάχιστον ένα κόμβο"); endif
	% Τοπικό σύστημα συντεταγμένων (προαιρετικό)
	if (node.hasAttribute("local_coordinate_system"))
		restraint.lcs = parseCoordinateSystem(node.getAttribute("local_coordinate_system"));
	endif
	% Δεσμεύσεις βαθμών ελευθερίας
	restraint.dofs = [];
	restraint = parseRestraintDOF(node, "disp_x", restraint, 1);
	restraint = parseRestraintDOF(node, "disp_y", restraint, 2);
	restraint = parseRestraintDOF(node, "disp_z", restraint, 3);
	restraint = parseRestraintDOF(node, "rot_x", restraint, 4);
	restraint = parseRestraintDOF(node, "rot_y", restraint, 5);
	restraint = parseRestraintDOF(node, "rot_z", restraint, 6);
	restraint = parseRestraintDOF(node, "warp", restraint, 6);
endfunction

% Λεκτική ανάλυση ενός xml element που είναι εξαναγκασμός
% in: node: Το xml element του στοιχείου.
% out: constraint: Octave δομή στοιχείου.
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function constraint = parseConstraint(node)
	parseCheckElementName(node, "constraint");
	constraint.id = node.getAttribute("id"); % Το node@id είναι προαιρετικό
	% Τοπικό σύστημα συντεταγμένων (προαιρετικό)
	if (node.hasAttribute("local_coordinate_system"))
		constraint.lcs = parseCoordinateSystem(node.getAttribute("local_coordinate_system"));
	endif
	% Φόρτωση των κόμβων των DoF
	nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	ii = length(nodes);
	if (~ii) error("Η δέσμευση πρέπει να έχει τουλάχιστον ένα κόμβο"); endif
	% Καταγραφή όλων των DoFs σε συνδυασμό με τους κόμβους τους
	dofs = strsplit(node.getAttribute("dofs"), " ");
	i = 1;	% index στον δεσμευμένο κόμβο που θα φορτωθεί πιο κάτω
	constraint.dofs = [];
	for dof = dofs
		switch(dof{1})
			case "disp_x" constraint.dofs = [constraint.dofs, [nodes(i); 1]];
			case "disp_y" constraint.dofs = [constraint.dofs, [nodes(i); 2]];
			case "disp_z" constraint.dofs = [constraint.dofs, [nodes(i); 3]];
			case "rot_x" constraint.dofs = [constraint.dofs, [nodes(i); 4]];
			case "rot_y" constraint.dofs = [constraint.dofs, [nodes(i); 5]];
			case "rot_z" constraint.dofs = [constraint.dofs, [nodes(i); 6]];
			case "warp" constraint.dofs = [constraint.dofs, [nodes(i); 7]];
			case "~"
				if (++i > ii)
					error(["Η δέσμευση έχει DoFs για περισσότερους κόμβους από τους ", num2str(ii), " που δίνονται"]);
				endif
			otherwise error(["Βρέθηκε μη έγκυρο όνομα βαθμού ελευθερίας: ", dof{1}]);
		endswitch
	endfor
	if (isempty(constraint.dofs)) error("Η δέσμευση πρέπει να περιλαμβάνει τουλάχιστον ένα βαθμό ελευθερίας"); endif
	% Αν οι DoFs δίνονται μόνο μια φορά για όλους τους κόμβους, επέκτεινε τους
	if (i == 1)
		j = columns(constraint.dofs);
		dofs = constraint.dofs;
		for i = 2:ii
			dofs(1, :) = nodes(i);
			constraint.dofs = [constraint.dofs, dofs];
		endfor
	endif
	% Φόρτωση του πίνακα Φ (συσχετίσεως των DoFs)
	% Είναι στο #text
	if (~isempty(node.getFirstChild) && node.getFirstChild.getNodeType == 3) # TEXT_NODE
		i = columns(constraint.dofs) + 1;
		nums = str2num(node.getFirstChild.getNodeValue);
		j = length(nums);
		if (mod(j, i))
			error(["Για ", num2str(i - 1), " δεσμευμένους κόμβους αναμένεται για τον πίνακα, πλήθος στοιχείων πολλαπλάσιο των ", ...
					num2str(i), ", βρέθηκαν ", num2str(j)]);
		endif
		% Ο πίνακας σχέσεων μεταξύ των μετακινήσεων
		constraint.disp_eq = reshape(nums, i, j / i)';
		constraint.disp_const = constraint.disp_eq(:, i)';
		constraint.disp_eq(:, i) = [];
	endif
endfunction

% Λεκτική ανάλυση μιας ομάδας αντικειμένων του xml, π.χ. materials ή nodes
% in: node: Το xml element της ομάδας για λεκτική ανάλυση
% in: name: Το όνομα που πρέπει να έχει το xml element της ομάδας.
% Δεν γίνεται έλεγχος αν το node έχει αυτό το όνομα.
% in: func: Μια συνάρτηση επεξεργασίας των παιδικών xml element του xml element
% της ομάδας
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function parseGroupOfNoCheck(node, name, func)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	child = node.getFirstElementChild;
	data.(name) = {};
	while ~isempty(child)
		try
			newIdx = length(data.(name)) + 1;
			item.id = num2str(newIdx);		% Αποθηκεύεται προσωρινά για το error handling
			item = func(child);
			% Έλεγχος εγκυρότητας id
			if (length(item.id))
				if (~isXmlName(item.id)) error(["Μη έγκυρη σύνταξη για το @id=", item.id]); endif
				data.map.(name).(item.id) = newIdx;	% Καταχώρηση σε ευρετήριο φιλικών ονομάτων
			else
				item.id = num2str(newIdx);		% Αλλιώς το id είναι ο αύξων αριθμός
			endif
			% Καταχώρηση σε βιβλιοθήκη
			data.(name){newIdx} = item;
			child = child.getNextElementSibling;
		catch err
			err.message = ["Πρόβλημα στη βιβλιοθήκη ", name, ", στο στοιχείο ", item.id, "\n", err.message];
			error(err);
		end_try_catch
	endwhile
endfunction

% Λεκτική ανάλυση μιας ομάδας αντικειμένων του xml, π.χ. materials ή nodes
% in: node: Το xml element της ομάδας για λεκτική ανάλυση
% in: name: Το όνομα που πρέπει να έχει το xml element της ομάδας.
% Αν δεν έχει αυτό το όνομα είναι σφάλμα.
% in: func: Μια συνάρτηση επεξεργασίας των παιδικών xml element του xml element
% της ομάδας
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function parseGroupOf(node, name, func)
	parseCheckElementName(node, name);
	parseGroupOfNoCheck(node, name, func);
endfunction

% Λεκτική ανάλυση μιας ομάδας αντικειμένων του xml, π.χ. materials ή nodes
% in: node: Το xml element της ομάδας για λεκτική ανάλυση
% in: name: Το όνομα που πρέπει να έχει το xml element της ομάδας.
% Αν δεν έχει αυτό το όνομα δεν φορτώνεται τίποτα.
% in: func: Μια συνάρτηση επεξεργασίας των παιδικών xml element του xml element
% της ομάδας
% out: parsed: true αν η βιβλιοθήκη υπήρχε
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function parsed = parseGroupOfIfExist(node, name, func)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	if (~isempty(node) && strcmp(node.getNodeName, name))
		parseGroupOfNoCheck(node, name, func);
		parsed = true;
	else data.(name) = {}; data.map.(name) = {}; parsed = false;
	endif
endfunction

%{
function parsed = parseOutputOptionsIfExist(library)
	global data;	% Τα δεδομένα του φορέα, όπως έχουν φορτωθεί μέχρι τώρα.
	solverDefaultSettings();
	if (~isempty(node) && strcmp(node.getNodeName, "output-options"))
		child = node.getFirstElementChild;
		% solver parsing
		if (~isempty(child) && strcmp(child.getNodeName, "solver"))
			b = child.getAttribute("tolerance");
			a = str2num(b);
			if (length(a))
				if (length(a) ~= 1 || a < 10^-15 || a > 10^-2)
					error(["Conjugent Gradient/Residuals tolerance πρέπει να είναι 10^-15 ως 10^-2, βρέθηκε ", b]);
				endif
				data.solver.settings.tolerance = a
			endif
			b = child.getAttribute("iterations");
			a = uint32(str2num(b));
			if (length(a))
				if (length(a) ~= 1 || ~a)
					error(["Conjugent Gradient/Residuals βήματα πρέπει να είναι από 1 και πάνω, βρέθηκε ", b]);
				endif
				data.solver.settings.iterations = a
			endif
			b = child.getAttribute("min-reaction");
			a = str2num(b);
			if (length(a))
				if (length(a) ~= 1 || ~a)
					error(["Conjugent Gradient/Residuals βήματα πρέπει να είναι από 1 και πάνω, βρέθηκε ", b]);
				endif
				data.solver.settings.minReaction = a
			endif
	data.solver.settings.minReaction = 0;
	data.solver.settings.minDisplacement = 0;

			child = child.getNextElementSibling;
		endif
	endif
endfunction
%}

% Φορτώνει το αρχείο xml του φορέα
% in: xml: Το όνομα αρχείου του αρχείου xml
% error: Σφάλμα κατά την λεκτική ανάλυση ή μη έγκυρα δεδομένα.
function parseXML(xml)
	try
		document = xmlread(xml);
		structure = document.getDocumentElement;
		parseCheckElementName(structure, "structure");
		% material parsing
		library = structure.getFirstElementChild;
		if (parseGroupOfIfExist(library, "materials", @parseMaterial))
			library = library.getNextElementSibling;
		endif
		% section parsing
		if (parseGroupOfIfExist(library, "frame_sections", @parseFrameSection))
			library = library.getNextElementSibling;
		endif
		% load parsing
		parseGroupOf(library, "loads", @parseLoad);
		library = library.getNextElementSibling;
		% node parsing
		parseGroupOf(library, "nodes", @parseNode);
		library = library.getNextElementSibling;
		% element parsing
		parseGroupOf(library, "elements", @parseElement);
		library = library.getNextElementSibling;
		% restraint parsing
		parseGroupOf(library, "restraints", @parseRestraint);
		library = library.getNextElementSibling;
		% constraint parsing
		if (parseGroupOfIfExist(library, "constraints", @parseConstraint))
			library = library.getNextElementSibling;
		endif
%{
		% output-options parsing
		if (parseOutputOptionsIfExist(library))
			library = library.getNextElementSibling;
		endif
%}
	catch err
		err.message = ["Πρόβλημα κατά την φόρτωση του αρχείου xml\n", err.message];
		error(err);
	end_try_catch;
endfunction;


% =============================================================== PRE-PROCESSING


% Υπολογίζει τα χαρακτηριστικά G των υλικών
function calcMaterialProperties()
	global data;
	for i = 1:length(data.materials)
		if (isfield(data.materials{i}, "v"))
			data.materials{i}.G = data.materials{i}.E / 2 / (1 + data.materials{i}.v);
		endif
	endfor
endfunction

% Υπολογίζει τα χαρακτηριστικά A, Iy, Iz, It, Cs διατομής τύπου Ο,
% ώστε να μη χρειάζεται πλέον το είδος διατομής
% in,out: section: Η διατομή πλαισίου
function section = calcFrameSection_O_Properties(section)
	section.A = section.diameter.^2 * pi / 4;
	section.Iz = section.Iy = section.diameter.^4 * pi / 64;
	if (length(section.A) == 2)
		section.A = section.A(1) - section.A(2);
		section.Iz = section.Iy = section.Iy(1) - section.Iy(2);
	endif
	section.It = section.Iz + section.Iy;
	section.It_S = section.Cs = 0;
endfunction

% Υπολογίζει τα χαρακτηριστικά A, Iy, Iz, It, Cs των διατομών,
% ώστε να μη χρειάζεται πλέον το είδος διατομής
% in,out: section: Η διατομή πλαισίου
function calcFrameSectionsProperties()
	global data;
	for i = 1:length(data.frame_sections)
		switch(data.frame_sections{i}.type)
			case "O"
				data.frame_sections{i} = calcFrameSection_O_Properties(data.frame_sections{i});
			case "generic"	% είναι όλα υπολογισμένα
			%TODO: Λοιπές διατομές
		endswitch
	endfor
endfunction

% Συμπληρώνει τα επικόμβια φορτία των κόμβων
function calcNodalLoads()
	global data;
	% Απαριθμεί έναν έναν όλους τους κόμβους
	for nodeidx = 1:length(data.nodes)
		node = data.nodes{nodeidx};
		% Απαρίθμηση των επικόμβιων φορτίων του κόμβου, αν υπάρχουν
		if (isfield(node, "loads"))
			data.nodes{nodeidx}.nodalLoads = zeros(1,7);
			for loadidx = node.loads
				load = data.loads{loadidx};
				% Αν είναι δύναμη ξεκινάει από το βαθμό ελευθερίας 1, ροπή από τον 4
				if (load.force) start = 1; else start = 4; endif
				data.nodes{nodeidx}.nodalLoads(start:start+2) += load.coords;
			endfor
		endif
	endfor
endfunction

% Αφαιρεί αχρείαστους βαθμούς ελευθερίας από ένα στοιχείο
% - Αφαιρεί τις μηδενικές γραμμές/στήλες από έναν πίνακα δυσκαμψίας στοιχείου
% - Προσαρμόζει το μητρώο στροφών σε αυτή την τροποποίηση
% - Προσαρμόζει τα ζεύγη node-DoF σε αυτή την τροποποίηση
% in, out: K: Το μητρώο δυσκαμψίας του στοιχείου
% in, out: lcs: Το μητρώο στροφών του στοιχείου
% in, out: dofs: Τα ζεύγη node-DoF
function [K, lcs, dofs] = compressStiffness(K, lcs, dofs)
	for i = rows(K):-1:1
		if (sum(abs(K(i, :))) < 256 * eps)
			K(i,:) = [];	% Διαγραφή γραμμής (πάει το φορτίο)
			K(:,i) = [];	% Διαγραφή στήλης (πάει η μετατόπιση)
			lcs(:,i) = [];	% Διαγραφή στήλης
			dofs(:,i) = [];	% Διαγραφή στήλης (πάει ο βαθμός ελευθερίας)
		endif
	endfor
endfunction

% Με βάση τα ζεύγη node-DoF ενός στοιχείου, ενημερώνει τους αντίστοιχους κόμβους
% για το ποιοι DoFs τους χρησιμοποιούνται από το συγκεκριμένο στοιχείο.
% in: dofs: Τα ζεύγη node-DoF
function enableDoFsOnNodes(dofs)
	global data;
	for pair = dofs % Αθλιοτητα! Το for κανει απαρίθμηση στηλών και όχι γραμμών
		i = pair(1); % pair: [node index, dof index]
		if (~isfield(data.nodes{i}, "dofs")) data.nodes{i}.dofs = zeros(1, 7); endif
		data.nodes{i}.dofs(pair(2)) = true;
	endfor
endfunction

% Μετατρέπει τα φορτία των στοιχείων (εσωτερικά και κατανεμημένα) σε επικόμβια
% in: dofs: Πίνακας με 1η γραμμή τους κόμβους των φορτίων και 2η γραμμή το βαθμό ελευθερίας
% in: loads: Τα επικόμβια φορτία, ίσα σε αριθμό με τις στήλες του dofs
function convertElementLoadsToNodeLoads(dofs, loads)
	global data;
	for i = 1:columns(dofs)
		dof = dofs(:, i);
		if (~isfield(data.nodes{dof(1)}, 'nodalLoads')) data.nodes{dof(1)}.nodalLoads = zeros(1, 7); endif
		data.nodes{dof(1)}.nodalLoads(dof(2)) += loads(i);
	endfor
endfunction

% Κοινός κώδικας ράβδου και γραμμικού ελατηρίου
% Πληροφορίες στις κλήσεις createBarStiffness(), createLinearSpringStiffness()
% in, out: element: Το στοιχείο της ράβδου
% in: dofRange: Το εύρος των βαθμών ελευθερίας που επηρεάζει το στοιχείο.
% 1:3 για μεταφορικούς βαθμούς και 4:6 για στροφικούς.
function element = createLinearSpringCommon(element, dofRange)
	element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
	% Lookup Table: Κάθε γραμμή του μητρώου δυσκαμψίας σε ποιο ζεύγος κόμβου-DoF αντιστοιχεί
	% Εφαρμόζεται αυτό το αναστροφο format, γιατί η for απαριθμεί στήλες(!) και όχι γραμμές
	element.dofs(1, 1:3) = element.nodes(1);
	element.dofs(1, 4:6) = element.nodes(2);
	element.dofs(2, 1:3) = element.dofs(2, 4:6) = dofRange;
	% Έλεγχος μήπως στο καθολικό κάποιοι βαθμοί ελευθερίας δεν μας απασχολούν
	[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
			compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
	% Στροφή αρχικών P0 στο καθολικό
	if (isfield(element, "initial_load"))
		P = element.initial_load;
		element.loads = [P, -P];
		element.loadGlobal = element.loads * element.lcsMatrix;
	endif
	% Ενημέρωση των κόμβων για το ποιοι βαθμοί ελευθερίας ενεργοποιούνται από το στοιχείο
	enableDoFsOnNodes(element.dofs);
	if (isfield(element, "loadGlobal"))
		convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
	endif
endfunction

% Υπολογίζει όλα τα απαιτούμενα στοιχεία της ράβδου σε τοπικό και καθολικό σύστημα
% Υπολογίζει το L, το τοπικό και καθολικό K, το τοπικό και καθολικό P0,
% το τοπικό σύστημα συντεταγμένων και το μητρώο στροφής.
% Εντοπίζει ποιους βαθμούς ελευθερίας, ποιών κόμβων, εμπλέκει στο καθολικό σύστημα
% και ενημερώνει τους κόμβους για αυτούς.
% in, out: element: Το στοιχείο της ράβδου
function element = createBarStiffness(element)
	global data;
	% Ανάκτηση δεδομένων από τα index τους
	material = data.materials{element.material};
	section = data.frame_sections{element.section};
	node1 = data.nodes{element.nodes(1)}.coords;
	node2 = data.nodes{element.nodes(2)}.coords;
	% Υπολογισμός συστήματος συντεταγμένων
	element.L = norm(node2 - node1);
	if (~element.L) error(["Ράβδος ", element.id, ", μηδενικού μήκους"]); endif
	element.direction = (node2 - node1) / element.L;
	element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
	% Υπολογισμός μητρώου δυσκαμψίας
	K = material.E * section.A / element.L;
	element.stiffness = [K, -K; -K, K];
	element = createLinearSpringCommon(element, 1:3);
endfunction

% Υπολογίζει όλα τα απαιτούμενα στοιχεία του γραμμικού ελατηρίου σε τοπικό και καθολικό σύστημα
% Υπολογίζει το τοπικό και καθολικό K, το τοπικό και καθολικό P0,
% το τοπικό σύστημα συντεταγμένων και το μητρώο στροφής.
% Εντοπίζει ποιους βαθμούς ελευθερίας, ποιών κόμβων, εμπλέκει στο καθολικό σύστημα
% και ενημερώνει τους κόμβους για αυτούς.
% in, out: element: Το στοιχείο του ελατηρίου
function element = createLinearSpringStiffness(element)
	if (length(element.nodes) == 1)
		% Υπολογισμός συστήματος συντεταγμένων
		element.lcsMatrix = element.direction;
		% Υπολογισμός μητρώου δυσκαμψίας
		element.stiffness = element.K;
		element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
		% Lookup Table: Κάθε γραμμή του μητρώου δυσκαμψίας σε ποιο ζεύγος κόμβου-DoF αντιστοιχεί
		% Εφαρμόζεται αυτό το αναστροφο format, γιατί η for απαριθμεί στήλες(!) και όχι γραμμές
		element.dofs(1, 1:3) = element.nodes(1);
		element.dofs(2, 1:3) = 1:3;
		% Έλεγχος μήπως στο καθολικό κάποιοι βαθμοί ελευθερίας δεν μας απασχολούν
		[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
				compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
		% Στροφή αρχικών P0 στο καθολικό
		if (isfield(element, "initial_load"))
			element.loads = element.initial_load;
			element.loadGlobal = element.loads * element.lcsMatrix;
		endif
		% Ενημέρωση των κόμβων για το ποιοι βαθμοί ελευθερίας ενεργοποιούνται από το στοιχείο
		enableDoFsOnNodes(element.dofs);
		if (isfield(element, "loadGlobal"))
			convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
		endif
	else
		% Υπολογισμός συστήματος συντεταγμένων
		element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
		% Υπολογισμός μητρώου δυσκαμψίας
		element.stiffness = [element.K, -element.K; -element.K, element.K];
		element = createLinearSpringCommon(element, 1:3);
	endif
endfunction

% Υπολογίζει όλα τα απαιτούμενα στοιχεία του στροφικού ελατηρίου σε τοπικό και καθολικό σύστημα
% Υπολογίζει το τοπικό και καθολικό K, το τοπικό και καθολικό P0,
% το τοπικό σύστημα συντεταγμένων και το μητρώο στροφής.
% Εντοπίζει ποιους βαθμούς ελευθερίας, ποιών κόμβων, εμπλέκει στο καθολικό σύστημα
% και ενημερώνει τους κόμβους για αυτούς.
% in, out: element: Το στοιχείο του ελατηρίου
function element = createTorsionSpringStiffness(element)
	if (length(element.nodes) == 1)
		% Υπολογισμός συστήματος συντεταγμένων
		element.lcsMatrix = element.direction;
		% Υπολογισμός μητρώου δυσκαμψίας
		element.stiffness = element.K;
		element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
		% Lookup Table: Κάθε γραμμή του μητρώου δυσκαμψίας σε ποιο ζεύγος κόμβου-DoF αντιστοιχεί
		% Εφαρμόζεται αυτό το αναστροφο format, γιατί η for απαριθμεί στήλες(!) και όχι γραμμές
		element.dofs(1, 1:3) = element.nodes(1);
		element.dofs(2, 1:3) = 4:6;
		% Έλεγχος μήπως στο καθολικό κάποιοι βαθμοί ελευθερίας δεν μας απασχολούν
		[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
				compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
		% Στροφή αρχικών P0 στο καθολικό
		if (isfield(element, "initial_load"))
			element.loads = element.initial_load;
			element.loadGlobal = element.loads * element.lcsMatrix;
		endif
		% Ενημέρωση των κόμβων για το ποιοι βαθμοί ελευθερίας ενεργοποιούνται από το στοιχείο
		enableDoFsOnNodes(element.dofs);
		if (isfield(element, "loadGlobal"))
			convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
		endif
	else
		% Υπολογισμός συστήματος συντεταγμένων
		element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
		% Υπολογισμός μητρώου δυσκαμψίας
		element.stiffness = [element.K, -element.K; -element.K, element.K];
		element = createLinearSpringCommon(element, 4:6);
	endif

endfunction

% Υπολογίζει όλα τα απαιτούμενα στοιχεία της δοκού σε τοπικό και καθολικό σύστημα
% Υπολογίζει το L, το τοπικό και καθολικό K, το τοπικό και καθολικό P0,
% το τοπικό σύστημα συντεταγμένων και το μητρώο στροφής.
% Εντοπίζει ποιους βαθμούς ελευθερίας, ποιών κόμβων, εμπλέκει στο καθολικό σύστημα
% και ενημερώνει τους κόμβους για αυτούς.
% in, out: element: Το στοιχείο της ράβδου
function element = createBeamStiffness(element)
	global data;
	% Ανάκτηση δεδομένων από τα index τους
	material = data.materials{element.material};
	section = data.frame_sections{element.section};
	node1 = data.nodes{element.nodes(1)}.coords;
	node2 = data.nodes{element.nodes(2)}.coords;
	% Υπολογισμός συστήματος συντεταγμένων
	L = element.L = norm(node2 - node1);
	if (~element.L) error(["Δοκός ", element.id, ", μηδενικού μήκους"]); endif
	axisX = (node2 - node1) / element.L;
	if (isfield(element, "axisZ"))	% είναι μοναδιαίο
		axisZ = element.axisZ;
		element = rmfield(element, "axisZ");
		axisY = cross(axisZ, axisX);
		n = norm(axisY);
		if (n < 0.02)
			error(["Στο δοκό ", element.id, ", ο άξονας z πρέπει να έχει γωνία τουλάχιστον 1.145° με τον άξονα x, έχει ", ...
					num2str(asin(n * 180 / pi)), "°"]);
		endif
		axisY /= n;
		axisZ = cross(axisX, axisY);
		element.lcs = [axisX; axisY; axisZ];
	else
		axisZ = [0 0 1];
		n = dot(axisX, axisZ);
		if (abs(n) > 0.9998)
			axisZ = -sign(n) * [1 0 0];
		endif
		axisY = cross(axisZ, axisX);
		axisY /= norm(axisY);
		axisZ = cross(axisX, axisY);
		element.lcs = [axisX; axisY; axisZ];
	endif
	% Στρέβλωση, στροφές και μετακινήσεις
	element.lcsMatrix(14, 14) = element.lcsMatrix(7, 7) = 1;
	element.lcsMatrix(1:3, 1:3) = element.lcsMatrix(4:6, 4:6) = ...
	element.lcsMatrix(8:10, 8:10) = element.lcsMatrix(11:13, 11:13) = element.lcs;
	%
	% Υπολογισμός συνολικού κατανεμημένου φορτίου
	if (isfield(element, 'distributed_loads'))
		P = zeros(2, 6);
		for i = element.distributed_loads
			load = data.loads{i};
			% Αν είναι στο καθολικό σύστημα, στροφή στο τοπικό
			if (~load.lcs) load.coords *= element.lcs'; endif
			% Θεωρούμε ότι είναι τραπεζοειδούς κατανομής (η πιο γενικευμένη περίπτωση που υποστηρίζεται)
			if (~isfield(load, "magnitude")) load.coords .*= [1;1];
			else load.coords .*= load.magnitude';	% Με 2 στοιχεία. Αν ήταν με 1, θα ειχε ενσωματωθεί στο .coords
			endif
			a = load.coords(1,1); b = load.coords(2,1);
			if (load.force) P(:, 1:3) += load.coords;
			else P(:, 4:6) += load.coords;
			endif
		endfor
		element.distributed_loads = P;
	endif
	%
	% Υπολογισμός μητρώου δυσκαμψίας
	%
	% Υπολογισμός σταθεράς εφελκυσμού/θλίψης
	E = material.E;
	if (isfield(section, "A"))
		A = section.A;
		K11 = E * A / L;
	else
		warning(["Δοκός ", element.id, ", με διατομή ", section.id, ...
				", δίχως A: Θεωρώ ότι δεν παραλαμβάνει αξονική δύναμη"]);
		A = 0;
		K11 = 0;
	endif
	%
	% Υπολογισμός σταθερών κάμψης-διάτμησης
	% Κάμψη στον άξονα z
	if (isfield(section, "Iz"))
		Iz = section.Iz;
		if (isfield(material, "G") && A && isfield(section, "ay"))
			G = material.G; ay = section.ay;
			% Υπολογισμός σταθερών κάμψης-διάτμησης Timoshenko
			c5 = A * G * Iz * E; c2 = A * G * L^2; c6 = ay * Iz * E; c7 = c2 + 12 * c6;
			K22 = 12 * c5 / c7 / L;
			K62 = 6 * c5 / c7;
			K66 = 4 * Iz * E * (c2 + 3 * c6) / c7 / L;
			KD6 = 2 * Iz * E * (c2 - 6 * c6) / c7 / L;
		else
			warning(["Δοκός ", element.id, ", με υλικό ", material.id, " δίχως v ή διατομή ", ...
					section.id, " δίχως A και ay: Θα χρησιμοποιηθεί κάμψη Euler, στον άξονα z"]);
			% Υπολογισμός σταθερών κάμψης Euler
			c = E * Iz / L;
			K22 = 12 * c / L^2;
			K62 =  6 * c / L;
			K66 =  4 * c;
			KD6 =  2 * c;
		endif
	else
		warning(["Δοκός ", element.id, ", με διατομή ", section.id, ...
				", δίχως Iz: Θεωρώ ότι δεν αντιστέκεται σε κάμψη στον άξονα z"]);
		K22 = K62 = K66 = KD6 = 0;
	endif
	% Κάμψη στον άξονα y
	if (isfield(section, "Iy"))
		Iy = section.Iy;
		if (isfield(material, "G") && A && isfield(section, "az"))
			G = material.G; az = section.az;
			% Υπολογισμός σταθερών κάμψης-διάτμησης Timoshenko
			c1 = A * G * Iy * E; c2 = A * G * L^2; c3 = az * Iy * E; c4 = c2 + 12 * c3;
			K33 = 12 * c1 / c4 / L;
			K53 = -6 * c1 / c4;
			K55 = 4 * Iy * E * (c2 + 3 * c3) / c4 / L;
			KC5 = 2 * Iy * E * (c2 - 6 * c3) / c4 / L;
		else
			warning(["Δοκός ", element.id, ", με υλικό ", material.id, " δίχως v ή διατομή ", ...
					section.id, " δίχως A και az: Θα χρησιμοποιηθεί κάμψη Euler, στον άξονα y"]);
			% Υπολογισμός σταθερών κάμψης Euler
			c = E * Iy / L;
			K33 = 12 * c / L^2;
			K53 = -6 * c / L;
			K55 =  4 * c;
			KC5 =  2 * c;
		endif
	else
		warning(["Δοκός ", element.id, ", με διατομή ", section.id, ...
				", δίχως Iz: Θεωρώ ότι δεν αντιστέκεται σε κάμψη στον άξονα z"]);
		K33 = K53 = K55 = KC5 = 0;
	endif
	%
	% Υπολογισμός σταθερών στρέψης-στρέβλωσης
	if (isfield(material, "G") && isfield(section, "It"))
		G = material.G;
		if (all(isfield(section, {"It_S", "Cs"})))
			ItP = section.It; ItS = section.It_S; Cs = section.Cs;
			% Υπολογισμός σταθερών ανομοιόμορφης στρέψης-στρέβλωσης με STMDE
			t1 = sqrt(E * Cs * ItS); t2 = sqrt(G * ItP); t3 = sqrt(ItP + ItS);
			t4 = t2 * ItS * L / (2 * t1 * t3); t5 = e^(2 * t4); t6 = t2 * t3 * L;
			K44 = t2^2 / (L * (1 - 2 * t1 * tanh(t4) / t6));
			K74 = t2^2 / (t6 * coth(t4) / t1 - 2);
			K77 = (t1 * t2 * t6 * (t5^2 + 1) - t1^2 * t2 * (t5^2 - 1)) / ...
						(t3 * t6 * (t5^2 - 1) - 2 * t1 * t3 * (t5 - 1)^2);
			KE7 = (2 * t1^2 * t2 * cosh(t4) - t1 * t2 * t6 * csch(t4)) / ...
						(2 * t3 * t6 * cosh(t4) - 4 * t1 * t3 * sinh(t4));
		elseif (isfield(section, "Cs"))
			It = section.It; Cs = section.Cs;
			% Υπολογισμός σταθερών ανομοιόμορφης στρέψης-στρέβλωσης
			t1 = sqrt(E * Cs); t2 = sqrt(G * It); t3 = t2 / t1; t4 = t3 * L / 2;
			t5 = e^(2 * t4); t6 = t2 * L * (t5^2 - 1) - 2 * t1 * (t5 - 1)^2;
			K44 = t2^2 / (L * (1 - tanh(t4) / t4));
		else
			It = section.It;
			% Υπολογισμός σταθερών κάμψης Saint Venant
			K44 = G * It / L;
			K74 = K77 = KE7 = 0;
			if (element.warp)	% Αν η δοκός υποστηρίζει στρέβλωση
				warning(["Δοκός ", element.id, ", υποστηρίζει στρέβλωση, αλλά λύνεται σαν ", section.id, ...
				", δίχως Iz: Θεωρώ ότι δεν αντιστέκεται σε κάμψη στον άξονα z"]);
			endif
		endif
		% Αν η δοκός δεν υποστηρίζει στρέβλωση κάνουμε συμπύκνωση της
		if (~element.warp)
			if (K77 + KE7) K44 -= 2 * K74^2 / (K77 + KE7); endif
			K74 = K77 = KE7 = 0;
		endif
	else
		warning(["Δοκός ", element.id, ", με υλικό ", material.id, " δίχως v ή διατομή ", ...
					section.id, " δίχως It: Θεωρώ ότι δεν αντιστέκεται σε στρέψη"]);
		K44 = K74 = K77 = KE7 = 0;
	endif
	%
	% Το μητρώο
	element.stiffness = [
			K11,  0,    0,    0,    0,    0,    0,    -K11, 0,    0,    0,    0,    0,    0;
			0,    K22,  0,    0,    0,    K62,  0,    0,    -K22, 0,    0,    0,    K62,  0;
			0,    0,    K33,  0,    K53,  0,    0,    0,    0,    -K33, 0,    K53,  0,    0;
			0,    0,    0,    K44,  0,    0,    K74,  0,    0,    0,    -K44, 0,    0,    K74;
			0,    0,    K53,  0,    K55,  0,    0,    0,    0,    -K53, 0,    KC5,  0,    0;
			0,    K62,  0,    0,    0,    K66,  0,    0,    -K62, 0,    0,    0,    KD6,  0;
			0,    0,    0,    K74,  0,    0,    K77,  0,    0,    0,    -K74, 0,    0,    KE7;

			-K11, 0,    0,    0,    0,    0,    0,    K11,  0,    0,    0,    0,    0,    0;
			0,    -K22, 0,    0,    0,    -K62, 0,    0,    K22,  0,    0,    0,    -K62, 0;
			0,    0,    -K33, 0,    -K53, 0,    0,    0,    0,    K33,  0,    -K53, 0,    0;
			0,    0,    0,    -K44, 0,    0,    -K74, 0,    0,    0,    K44,  0,    0,    -K74;
			0,    0,    K53,  0,    KC5,  0,    0,    0,    0,    -K53, 0,    K55,  0,    0;
			0,    K62,  0,    0,    0,    KD6,  0,    0,    -K62, 0,    0,    0,    K66,  0;
			0,    0,    0,    K74,  0,    0,    KE7,  0,    0,    0,    -K74, 0,    0,    K77];

	element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
	% Lookup Table: Κάθε γραμμή του μητρώου δυσκαμψίας σε ποιο ζεύγος κόμβου-DoF αντιστοιχεί
	% Εφαρμόζεται αυτό το αναστροφο format, γιατί η for απαριθμεί στήλες(!) και όχι γραμμές
	element.dofs(1, 1:7) = element.nodes(1);
	element.dofs(1, 8:14) = element.nodes(2);
	element.dofs(2, 1:3) = element.dofs(2, 8:10) = 1:3;		% Μετακινησιακοί
	element.dofs(2, 4:6) = element.dofs(2, 11:13) = 4:6;	% Στροφικοί
	element.dofs(2, 7) = element.dofs(2, 14) = 7;					% Στρέβλωση
	% Έλεγχος μήπως στο καθολικό κάποιοι βαθμοί ελευθερίας δεν μας απασχολούν
	[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
			compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
	%
	% Κατανεμημένα φορτία
	if (isfield(element, "distributed_loads"))
		P = zeros(1, 14);
		% Αξονική ισοδύναμη επικόμβια δράση
		a = element.distributed_loads(1,1); b = element.distributed_loads(2,1);
		if (a || b)
			P(1) -= -L * (2 * a + b) / 6;
			P(8) -= -L * (a + 2 * b) / 6;
		endif
		% Τέμνουσα στον άξονα y ισοδύναμη επικόμβια δράση (κάμψη στον άξονα z)
		a = element.distributed_loads(1,2); b = element.distributed_loads(2,2);
		if (a || b)
			if (exist("ay"))	% Timoshenko
				P(2) -= -L * ((7 * a + 3 * b) * c2 + 40 * (2 * a + b) * c6) / (20 * c7);
				P(6) -= -L^2 * ((3 * a + 2 * b) * c2 + 30 * (a + b) * c6) / (60 * c7);
				P(9) -= -L * ((3 * a + 7 * b) * c2 + 40 * (a + 2 * b) * c6) / (20 * c7);
				P(13) -= L^2 * ((2 * a + 3 * b) * c2 + 30 * (a + b) * c6) / (60 * c7);
			else							% Euler
				P(2) -= -L * (7 * a + 3 * b) / 20;
				P(6) -= -L^2 * (3 * a + 2 * b) / 60;
				P(9) -= -L * (3 * a + 7 * b) / 20;
				P(13) -= L^2 * (2 * a + 3 * b) / 60;
			endif
		endif
		% Τέμνουσα στον άξονα z ισοδύναμη επικόμβια δράση (κάμψη στον άξονα y)
		a = element.distributed_loads(1,3); b = element.distributed_loads(2,3);
		if (a || b)
			if (exist("az"))	% Timoshenko
				P(3) -= -L * ((7 * a + 3 * b) * c2 + 40 * (2 * a + b) * c3) / (20 * c4);
				P(5) -= L^2 * ((3 * a + 2 * b) * c2 + 30 * (a + b) * c3) / (60 * c4);
				P(10) -= -L * ((3 * a + 7 * b) * c2 + 40 * (a + 2 * b) * c3) / (20 * c4);
				P(12) -= -L^2 * ((2 * a + 3 * b) * c2 + 30 * (a + b) * c3) / (60 * c4);
			else							% Euler
				P(3) -= -L * (7 * a + 3 * b) / 20;
				P(5) -= L^2 * (3 * a + 2 * b) / 60;
				P(10) -= -L * (3 * a + 7 * b) / 20;
				P(12) -= -L^2 * (2 * a + 3 * b) / 60;
			endif
		endif
		% Ροπή στον άξονα x ισοδύναμη επικόμβια δράση (στρέψη)
		a = element.distributed_loads(1,4); b = element.distributed_loads(2,4);
		if (a || b)
			if (exist("ItP"))		% Ανομοιόμορφη στρέψη με STMDE
				p7 = t4 * L * cosh(t4);
				p8 = 3 * t1 * L * sinh(t4);
				p9 = 3 * t1 * (a - b);
				p10 = t4 * t6;
				p11 = 12 * t2 * t3 * t4^2 * (t6 * coth(t4) - 2 * t1);
				p12 = (a + b) * t1 * t4;
				p13 = 6 * t4^2 * (t6 * cosh(t4) - 2 * t1 * sinh(t4));
				P(4) -= (p7 * (p9 - (2 * a + b) * p10) - p8 * (a - b - (a + b) * t4^2)) / p13;
				P(7) -= t1 * L * (-6 * p12 - t6 * (3 * (a - b) + 2 * t4^2 * (2 * a + b)) ...
						+ 6 * t4 * (p12 + a * t6) * coth(t4) - 3 * (a + b) * t6 * t4^2 * csch(t4)^2) / p11;
				P(11) -= -(p7 * (p9 + (a + 2 * b) * p10) - p8 * (a - b + (a + b) * t4^2)) / p13;
				P(14) -= t1 * L * (6 * p12 - t6 * (3 * (a - b) - 2 * t4^2 * (a + 2 * b)) ...
						- 6 * t4 * (p12 + b * t6) * coth(t4) + 3 * (a + b) * t6 * t4^2 * csch(t4)^2) / p11;
			elseif(exist("Cs"))	% Ανομοιόμορφη στρέψη
				p1 = (a - b) / (t3^2 * L);
				p2 = (a + b) * L / 4;
				p3 = t4 * (a - b) * L / (12(t4 - tanh(t4)));
				P(4) -= p1 - p2 - p3;
				P(7) -= a / t3^2 - (a + b) * L * coth(t4) / (4 * t3) ...
								- (a - b) * L^2 / (24 * (t4 * coth(t4) - 1));
				P(11) -= -p1 - p3 + p3;
				P(14) -= (6 * b + 2 * (a + 2 * b) * t4^2 + 3 * t4 * ((a + b) * t4 * csch(t4)^2 - (a + 3 * b) * coth(t4))) ...
						/ (6 * t3^2 *(t4 * coth(t4) - 1));
			else								% Ομοιόμορφη στρέψη Saint Venant
				P(4) -= -(2 * a + b) * L / 6;
				P(11) -= -(a + 2 * b) * L / 6;
			endif
		endif
		% Ροπή στον άξονα y ισοδύναμη επικόμβια δράση (κάμψη στον άξονα y)
		a = element.distributed_loads(1,5); b = element.distributed_loads(2,5);
		if (a || b)
			if (exist("az"))	% Timoshenko
				P(3) -= -((a - b) * c2 + 24 * a * c3) / (2 * c4);
				P(5) -= L * ((a - b) * c2 + 24 * (2 * a + b) * c3) / (12 * c4);
				P(10) -= (-(a - b) * c2 + 24 * b * c3) / (2 * c4);
				P(12) -= L * (-(a - b) * c2 + 24 * (a + 2 * b) * c3) / (12 * c4);
			else							% Euler
				p1 = -(a - b) / 2;
				p2 = L * (a - b) / 12;
				P(3) -= p1;
				P(5) -= p2;
				P(10) -= p1;
				P(12) -= -p2;
			endif
		endif
		% Ροπή στον άξονα z ισοδύναμη επικόμβια δράση (κάμψη στον άξονα z)
		a = element.distributed_loads(1,6); b = element.distributed_loads(2,6);
		if (a || b)
			if (exist("ay"))	% Timoshenko
				P(2) -= ((a - b) * c2 + 24 * a * c6) / (2 * c7);
				P(6) -= L * ((a - b) * c2 + 24 * (2 * a + b) * c6) / (12 * c7);
				P(9) -= ((a - b) * c2 - 24 * b * c6) / (2 * c7);
				P(13) -= L * (-(a - b) * c2 + 24 * (a + 2 * b) * c6) / (12 * c7);
			else							% Euler
				p1 = (a - b) / 2;
				p2 = L * (a - b) / 12;
				P(2) -= p1;
				P(6) -= p2;
				P(9) -= p1;
				P(13) -= -p2;
			endif
		endif
		element.loads = P;
	endif
	%
	% Επικόμβιες δράσεις πλην κατανεμημένων φορτίων
	if (isfield(element, "initial_load"))
		P = element.initial_load;
		P = [P, -P];
		if (isfield(element, "loads")) element.loads += P; else element.loads = P; endif
	endif
	% Στροφή αρχικών P0 στο καθολικό
	if (isfield(element, "loads"))
		element.loadGlobal = element.loads * element.lcsMatrix;
		% Έλεγχος μήπως χάσουμε κάποια συνιστώσα φορτίου λόγω απόρριψης γραμμοστήλης δυσκαμψίας
		if (norm(element.loadGlobal * element.lcsMatrix' - element.loads) > 256 * eps)
			error(["Η δοκός ", element.id, ", έχει συνιστώσα φόρτισης σε βαθμό ελευθερίας που δεν παρουσιάζει δυσκαμψία"]);
		endif
	endif
	% Ενημέρωση των κόμβων για το ποιοι βαθμοί ελευθερίας ενεργοποιούνται από το στοιχείο
	enableDoFsOnNodes(element.dofs);
	if (isfield(element, "loadGlobal"))
		convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
	endif
endfunction


% Υπολογίζει όλα τα απαιτούμενα στοιχεία, όλων των στοιχείων του φορέα.
function calcElementsStiffness()
	global data;
	for i = 1:length(data.elements)
		switch(data.elements{i}.type)
			case 0 % bar
				data.elements{i} = createBarStiffness(data.elements{i});
			case 1 % linear spring
				data.elements{i} = createLinearSpringStiffness(data.elements{i});
			case 2 % torsion spring
				data.elements{i} = createTorsionSpringStiffness(data.elements{i});
			case 3 % beam
				data.elements{i} = createBeamStiffness(data.elements{i});
			%TODO: Λοιπά στοιχεία
		endswitch
	endfor
endfunction

% Μετατροπή όλων των καταναγκασμών σε εξαναγκασμούς που είναι η πιο γενικευμένη μορφή
% Πως γίνεται αυτό: Αν έχουμε π.χ. ux = 0.001 τότε ο διανυσματικός χώρος είναι το 1
% και ο σταθερός όρος το 0.01.
% Δημιουργείται ένας εξαναγκασμός για κάθε δεσμευμένο βαθμό ελευθερίας κάθε κόμβου.
function convertRestraintsToConstraints()
	global data;
	pos = length(data.constraints);
	for i = 1:length(data.restraints)
		restraint = data.restraints{i};
		constraint.id = ["restraint: ", restraint.id];
		if (isfield(restraint, "lcs")) constraint.lcs = restraint.lcs; endif
		constraint.disp_eq = 1;
		for dof = restraint.dofs
			constraint.disp_const = dof(2);
			for node = restraint.nodes
				constraint.dofs = [node; dof(1)];
				data.constraints{++pos} = constraint;		% Προσθήκη εξαναγκασμού στη λίστα εξαναγκασμών
			endfor
		endfor
	endfor
endfunction

% Υπολογίζει τις εξισώσεις που συνδέουν τις μετατοπίσεις, ενός συστήματος αξόνων
% in: con: Ο εξαναγκασμός
% out: eq: Οι εξισώσεις που συνδέουν τις μετατοπίσεις
function eq = makeRigidConstraint(con)
	global data;
	c = [0 0 0];						% Κέντρο βάρους των μεταφορικών βαθμών ελευθερίας
	n = [0 0 0  0 0 0  0];	% Αριθμός βαθμών ελευθερίας σε κάθε στροφικό/μεταφορικό άξονα
	f = [0 0 0];						% Index του 1ου στροφικού βαθμού ελευθερίας στη λίστα των DoFs
	cols = columns(con.dofs);
	for i = 1:cols
		dof = con.dofs(:, i);
		++n(dof(2));
		if (dof(2) <= 3) c(dof(2)) += data.nodes{dof(1)}.coords(dof(2));
		elseif (dof(2) <= 6 && ~f(dof(2) - 3)) f(dof(2) - 3) = i;
		endif
	endfor
	c ./= n(1:3);	% Από sum σε average
	% Έλεγχος για εσφαλμένα δεδομένα
	if (n(1) == 1 || n(2) == 1 || n(3) == 1 || n(7) == 1 || ...
			n(4) == 1 && n(2) < 2 && n(3) < 2 || ...
			n(5) == 1 && n(1) < 2 && n(3) < 2 || ...
			n(6) == 1 && n(1) < 2 && n(2) < 2)
		error(["Στον εξαναγκασμό στερεού ", con.id, " υπάρχουν μεμονωμένοι βαθμοί ελευθερίας"]);
	endif
	% Η επόμενη εξίσωση για τον κάθε βαθμό ελευθερίας πρέπει να αγνοηθεί γιατί δεν είναι γραμμικά ανεξάρτητη
	skip = [true, true, true,  true, true, true,  true];
	eq = [];	% Εξισώσεις Lagrange
	ii = 0; % Τρέχουσα εξίσωση
	for i = 1:cols
		dof = con.dofs(:, i);
		% Η πρώτη σχέση σε κάθε άξονα στροφικό ή μεταφορικό αγνοείται επειδή δεν είναι γραμμικά ανεξάρτητη
		% Η επιλογή της πρώτης είναι τυχαία. Οποιαδήποτε σχέση θα μπορούσε να είναι.
		if (skip(dof(2))) skip(dof(2)) = false;
		else
			++ii;
			% Δημιουργία εξίσωσης διχως αλληλεπίδραση στροφής-μετακίνησης
			for j = 1:cols
				if (i == j) eq(ii, j) = 1 / n(dof(2)) - 1;		% Κύρια διαγώνιος
				elseif (dof(2) == con.dofs(2, j)) eq(ii, j) = 1 / n(dof(2));	% Βαθμοί ελευθερίας στον ίδιο άξονα
				endif
			endfor
			% Προσθήκη αλληλεπίδρασης στροφής-μετακίνησης στη δημιουργηθείσα εξίσωση
			switch(dof(2))
				case 1	% Μετακινησιακός βαθμός ελευθερίας x
					if (f(2)) eq(ii, f(2)) = data.nodes{dof(1)}.coords(3) - c(3); endif
					if (f(3)) eq(ii, f(3)) = -(data.nodes{dof(1)}.coords(2) - c(2)); endif
				case 2	% y
					if (f(1)) eq(ii, f(1)) = -(data.nodes{dof(1)}.coords(3) - c(3)); endif
					if (f(3)) eq(ii, f(3)) = data.nodes{dof(1)}.coords(1) - c(1); endif
				case 3	% z
					if (f(1)) eq(ii, f(1)) = data.nodes{dof(1)}.coords(2) - c(2); endif
					if (f(2)) eq(ii, f(2)) = -(data.nodes{dof(1)}.coords(1) - c(1)); endif
			endswitch
		endif
	endfor
endfunction

% Υπολογίζει ένα οποιοδήποτε συμπληρωματικό διανυσματικό υποχώρο ενός διανυσματικού υποχώρου
% in: A: οι γραμμές του πίνακα αποτελούν το διανυσματικό υποχώρο
% out: X: οι γραμμές του πίνακα αποτελούν το συμπληρωματικό υποχώρο του υποχώρου Α.
% Επιστρέφει nan αν ο υποχώρος Α είναι προβληματικός
function X = findComplementVectorSubspace(A)
	A = rref(A);
	swaps = [];		% Κρατάει τις αλλαγές στηλών προκειμένου ο Α να είναι ανυγμένος κλιμακωτός
	r = rows(A);
	if (~any(A(r, :))) X = nan; return; endif
	ii = 1;
	% Αντιμετάθεση στηλών ώστε ο Α να γίνει A = [I B]
	for i = 1:r
		while(~A(i, ii)) ii++; endwhile
		if (i ~= ii)
			swaps = [swaps, [i; ii]];
			x = A(:, i); A(:, i) = A(:, ii); A(:, ii) = x;
		endif
	endfor
	% Υπολογισμός του συμπληρωματικού διανυσματικού υποχώρου
	A = -A(:, r+1:columns(A))';
	r2 = rows(A);
	X = [A, eye(r2)];
	% Αντιμετάθεση στηλών ώστε ο Χ να γίνει όπως πρέπει
	for i = swaps
		x = X(:, i(1)); X(:, i(1)) = X(:, i(2)); X(:, i(2)) = x;
	endfor
endfunction

% Αρχικοποιεί τους εξαναγκασμούς μεταξύ βαθμών ελευθερίας
% Οι εξαναγκασμοί αρχικά περιγράφονται με εξισώσεις που συνδέουν τις μετατοπίσεις.
% Αυτό όμως δεν είναι αρκετό. Θα πρέπει να προστεθούν μερικές εξισώσεις (μία για
% κάθε στροφικό ή μεταφορικό άξονα) που να συνδέουν τις αντιδράσεις (ροπές/δυνάμεις).
% Τέλος αφού αποσαφηνιστεί πόσες εξισώσεις Lagrange δημιουργούνται, θα πρέπει να
% ενημερωθεί ο solver.
function linkConstrainedDoFs()
	global data;
	for cidx = 1:length(data.constraints)
		c = data.constraints{cidx};	% Συντόμευση
		% Αν δεν έχουν υπολογιστεί οι εξισώσεις των μετακινήσεων πρέπει να υπολογιστούν τώρα
		if (~isfield(c, "disp_eq"))
			c.disp_eq = makeRigidConstraint(c);
			c.disp_const = zeros(1, rows(c.disp_eq));
		endif
		% Στροφή του διανυσματικού χώρου των εξισώσεων των μετακινήσεων
		if (isfield(c, "lcs"))
			% Ο πίνακας στροφής των DoFs του κόμβου από καθολικό σε τοπικό σύστημα
			% αν οι DoFs υπήρχαν όλοι και ήταν με την κανονική σειρά
			% Ο πίνακας θα υποστεί αναδιάταξη
			R = zeros(7); R(4:6, 4:6) = R(1:3, 1:3) = c.lcs'; R(7, 7) = 1;
			% Οι βαθμοί ελευθερίας στο καθολικό σύστημα
			dofs = [];
			% Ο πίνακας στροφής των DoFs όλων των κόμβων της δέσμευσης
			Rr = [];
			i = 1;
			e = columns(c.dofs);
			while (i)
				% Ο αναδιατεταγμένος πίνακας στροφής των DoFs του κόμβου από καθολικό σε
				% τοπικό σύστημα, μόνο για όσους DoFs υπάρχουν
				RR = [];
				node = c.dofs(1, i);
				% Οι σειρά των DoFs του κόμβου στο καθολικό σύστημα
				% Αν κάποιες στήλες του RR είναι μηδενικές θα αφαιρεθούν, και μαζί οι
				% αντίστοιχες στήλες του u
				u = [node, node, node, node, node, node, node; 1 2 3 4 5 6 7];
				% Αναδιάταξη των γραμμών του R
				for j = i:i+7
					if (j > e) ii = 0; break; endif % Τελείωσαν οι DoFs της δέσμευσης
					if (node ~= c.dofs(1, j)) ii = j; break; endif % Που ξεκινάει ο επόμενος κόμβος
					RR = [RR; R(c.dofs(2, j), :)];
				endfor
				for j = columns(RR):-1:1
					if (~any(RR(:, j))) RR(:,j) = []; u(:,j) = []; endif
				endfor
				dofs = [dofs; u];			% Οι DoFs του κόμβου στη λίστα με όλους τους DoFs
				% Το μητρώο στροφής των DoFs του κόμβου στο μητρώο στροφής όλης της δέσμευσης
				rf = rows(Rr); rt = rf + rows(RR);
				cf = columns(Rr); ct = cf + columns(RR);
				Rr(rf+1:rt, cf+1:ct) = RR;
				i = ii;
			endwhile
			% Όλα τα τοπικά αντικαθίστανται από τα καθολικά
			c.disp_eq = c.disp_eq * Rr;
			c.dofs = dofs;
		endif
		% Έλεγχος αν οι βαθμοί ελευθερίας που δεσμεύονται υπάρχουν
		% Αν δεν υπάρχουν είναι σφάλμα
		% Αν υπάρχουν μαρκάρονται ότι σε αυτούς τους βαθμούς ελευθερίας θα αναπτυχθούν αντιδράσεις
		for i = c.dofs
			if (~data.nodes{i(1)}.dofs(i(2)))
				error(["Η δέσμευση ", c.id, " αναφέρεται στο βαθμό ελευθερίας ", ...
						num2str(i(2)), " του κόμβου ", data.nodes{i(1)}.id, ' που δεν υπάρχει']);
			else
				% Μαρκάρεται με 0 στον κόμβο ότι θα αναπτυχθεί βαθμός ελευθερίας (αλλιώς είναι nan)
				if (~isfield(data.nodes{i(1)}, "reactions")) data.nodes{i(1)}.reactions = nan(1, 7); endif
				data.nodes{i(1)}.reactions(i(2)) = 0;
			endif
		endfor
		% Έλεγχος αν οι εξισώσεις που υπάρχουν είναι ίσες με τους βαθμούς ελευθερίας
		% άρα προκαλούν καταναγκασμό (παγίωση)
		if (rows(c.disp_eq) == columns(c.dofs))
			% Έλεγχος αν αντιστρέφεται ο πίνακας
			if (rcond(c.disp_eq) < 256 * eps)
				error(["Οι σχέσεις των μετακινήσεων του εξαναγκασμού ", c.id, ...
						", δεν είναι σωστά μορφωμένες. Κάποιες είτε απαλείφονται, είτε αλληλοαναιρούνται."]);
			endif
			u = c.disp_const / c.disp_eq';		% επίλυση του συστήματος για να βρεθούν οι μετακινήσεις
			for i = 1:columns(c.dofs)
				dof = c.dofs(:, i);
				if (~isfield(data.nodes{dof(1)}, "displacements"))
					data.nodes{dof(1)}.displacements = nan(1, 7);
				endif
				data.nodes{dof(1)}.dofs(dof(2)) = -1;	% Μαρκάρεται ο DoF δεσμευμένος
				data.nodes{dof(1)}.displacements(dof(2)) = u(i); % Δεσμευμένος με τιμή
			endfor
		else
			% Υπολογισμός των εξισώσεων των αντιδράσεων εξαιτίας των εξαναγκασμών
			c.react_eq = findComplementVectorSubspace(c.disp_eq);
			if (isnan(c.react_eq))
				error(["Οι σχέσεις των μετακινήσεων του εξαναγκασμού ", c.id, ...
						", δεν είναι σωστά μορφωμένες. Κάποιες είτε απαλείφονται, είτε αλληλοαναιρούνται."]);
			endif
			% Ενημέρωση του solver για το πόσες εξισώσεις Lagrange θα προστεθούν εξαιτίας του εξαναγκασμού
			data.solver.totalLagrangeEquations += rows(c.disp_eq) + rows(c.react_eq);
			data.constraints{cidx} = c;
		endif
	endfor
endfunction

% Δημιουργεί έναν lookup table σε κάθε node που αντιστοιχούν τους βαθμούς ελευθερίας
% του σε κάποια γραμμοστήλη του μητρώου δυσκαμψίας του φορέα.
% Αν η τιμή είναι 0 σημαίνει ότι ο βαθμός ελευθερίας δεν είναι ενεργός.
% Αν είναι θετική σημαίνει ότι ο βαθμός ελευθερίας είναι ελεύθερος και δείχνει τη
% γραμμοστήλη στον αντίστοιχο πίνακα του φορέα.
% Αν είναι αρνητική σημαίνει ότι ο βαθμός ελευθερίας είναι δεσμευμένος και δείχνει τη
% γραμμοστήλη στον αντίστοιχο πίνακα του φορέα.
function makePermutationLookupTableOnNodes()
	global data;
	free = 0; fixed = 0;
	for i = 1:length(data.nodes)
		for j = 1:7
			if (data.nodes{i}.dofs(j) == 1)      data.nodes{i}.dofs(j) = ++free;
			elseif (data.nodes{i}.dofs(j) == -1) data.nodes{i}.dofs(j) = --fixed;
			endif
		endfor
	endfor
	% Καταχωρεί στο solver αριθμό ελεύθερων και δεσμευμένων βαθμών ελευθερίας
	data.solver.free = free;
	data.solver.freeAll = free + data.solver.totalLagrangeEquations;
	data.solver.fixed = -fixed;
	data.solver.nextLagrangeEquation = free + 1;	% Index της πρώτης θέσης για τοποθέτηση Lagrange εξίσωσης
endfunction

% Αρχικοποίηση πινάκων δυσκαμψίας και διανυσμάτων του φορέα
function initStructureStiffness()
	global data;
	% Δημιουργία πυκνών πινάκων για την συμπλήρωσή τους. Αργότερα θα γίνουν αραιοί.
	data.solver.stiffness1 = zeros(data.solver.freeAll);
	data.solver.stiffness2 = zeros(data.solver.fixed);
	data.solver.stiffness12 = zeros(data.solver.freeAll, data.solver.fixed);
	data.solver.loads1 = zeros(1, data.solver.freeAll);
	data.solver.loads2 = data.solver.displacements2 = zeros(1, data.solver.fixed);
endfunction

% Συμπληρώνει τα μητρώα και διανύσματα του φορέα, με τιμές από τα μέλη
function populateStructureStiffnessFromElements()
	global data;
	% Απαριθμεί ένα ένα τα μέλη του φορέα
	for element = data.elements
		element = element{1};
		% Το μητρώο δυσκαμψίας του μέλους στο μητρώο δυσκαμψίας του φορέα
		for i = 1:rows(element.stiffnessGlobal)
			for j = 1:columns(element.stiffnessGlobal)
				el = element.stiffnessGlobal(i, j);
				row = data.nodes{element.dofs(1, i)}.dofs(element.dofs(2, i));
				col = data.nodes{element.dofs(1, j)}.dofs(element.dofs(2, j));
				if (row > 0 && col > 0) data.solver.stiffness1(row, col) += el;
				elseif (row < 0 && col < 0) data.solver.stiffness2(-row, -col) += el;
				elseif (row > 0 && col < 0) data.solver.stiffness12(row, -col) += el;
				%else ο πίνακας stiffness21 δε χρειάζεται
				endif
			endfor
		endfor
		% Το διάνυσμα αρχικών φορτίων του μέλους στο διάνυσμα φορτίων του φορέα
		% δε χρειάζεται γιατί έχουν περαστεί τα φορτία στους κόμβους και θα γίνει από εκεί
	endfor
endfunction

% Προσθέτει μια εξίσωση Lagrange, που συνδέει μετατοπίσεις, στο μητρώο K.
% in: row: Η γραμμή στο μητρώο K, στην οποία θα προστεθεί η εξίσωση.
% in: coefs: Οι συντελεστές των βαθμών ελευθερίας που θα τοποθετηθούν στο Κ.
% in: dofs: Πίνακας με 1η γραμμή τα index των κόμβων και 2η γραμμή τα index των DoFs
% in: const: Ο σταθερός όρος της εξίσωσης Lagrange που τοποθετείται στο διάνυσμα
% των φορτίων.
% Η εξίσωση Lagrange είναι coefs * dofs = const.
function addDisplacementLagrangeEquation(row, coefs, dofs, const)
	global data;
	% Δεν χρειάζεται "+=" αλλά σκέτο "=" γιατί εκεί που είναι οι εξισώσεις Lagrance
	% δε γράφει κανένα άλλο στοιχείο.
	% σταθερός όρος εξίσωσης Φ Lagrange - τοποθετείται στο διάνυσμα των φορτίσεων
	data.solver.loads1(row) = const;
	% Οι όροι στους πίνακες stiffness1 και stiffness12
	% Τοποθετούνται μόνο σε γραμμές. Σε στήλες θα τοποθετηθούν με αναστροφή
	% του υποπίνακα των γραμμών (δεδομένου ότι το κομμάτι πίνακα πάνω στη
	% διαγώνιο είναι μηδενικό)
	for i = 1:columns(coefs)
		if (~coefs(i)) continue; endif
		col = data.nodes{dofs(1, i)}.dofs(dof = dofs(2, i));
		if (col > 0) data.solver.stiffness1(row, col) = coefs(i);
		else data.solver.stiffness12(row, -col) = coefs(i);
		endif
	endfor
endfunction

% Προσθέτει μια εξίσωση Lagrange, που συνδέει αντιδράσεις, στο μητρώο K.
% in: row: Η γραμμή στο μητρώο K, στην οποία θα προστεθεί η εξίσωση.
% in: coefs: Οι συντελεστές των αντιδράσεων που θα τοποθετηθούν στο Κ.
% in: dofs: Πίνακας με 1η γραμμή τα index των κόμβων και 2η γραμμή τα index των DoFs
% Η εξίσωση Lagrange είναι K * coefs * dofs = K * P.
function addReactionLagrangeEquation(row, coefs, dofs)
	global data;
	% Οι όροι στους πίνακες stiffness1 και stiffness12
	% Τοποθετούνται μόνο σε γραμμές. Σε στήλες θα τοποθετηθούν με αναστροφή
	% του υποπίνακα των γραμμών (δεδομένου ότι το κομμάτι πίνακα πάνω στη
	% διαγώνιο είναι μηδενικό)
	data.solver.stiffness1(row, :) = 0;  % Αρχικοποίηση γιατί μετά έχει "+="
	data.solver.stiffness12(row, :) = 0; % Αρχικοποίηση γιατί μετά έχει "+="
	data.solver.loads1(row) = 0;         % Αρχικοποίηση γιατί μετά έχει "+="
	for i = 1:columns(coefs)
		if (~coefs(i)) continue; endif
		rowSrc = data.nodes{dofs(1, i)}.dofs(dofs(2, i));
		data.solver.stiffness1(row, :) += coefs(i) * data.solver.stiffness1(rowSrc, :);
		data.solver.stiffness12(row, :) += coefs(i) * data.solver.stiffness12(rowSrc, :);
		data.solver.loads1(row) += coefs(i) * data.solver.loads1(rowSrc);
	endfor

endfunction

% Συμπληρώνει τα μητρώα του φορέα, με τιμές από τις εξισώσεις πολλαπλασιαστών Lagrange
% των εξαναγκασμών (constraints)
function populateStructureStiffnessFromConstraints()
	global data;
	% Απαριθμεί έναν έναν όλους τους εξαναγκασμούς του φορέα
	for con = data.constraints
		con = con{1};
		if (isfield(con, "react_eq"))	% Μια πλήρης δέσμευση βαθμών ελευθερίας δεν έχει σχέσεις Lagrange
			for i = 1:rows(con.disp_eq)
				addDisplacementLagrangeEquation(data.solver.nextLagrangeEquation++, ...
																	con.disp_eq(i, :), con.dofs, con.disp_const(i));
			endfor
			for i = 1:rows(con.react_eq)
				addReactionLagrangeEquation(data.solver.nextLagrangeEquation++, ...
																	con.react_eq(i, :), con.dofs);
			endfor
		endif
	endfor
endfunction

% Συμπληρώνει τα επικόμβια διανύσματα του φορέα με επικόμβια φορτία και επικόμβιες
% παγιωμένες μετατοπίσεις των καταναγκασμών (restraints)
function populateStructureStiffnessFromNodes()
	global data;
	% Απαριθμεί έναν έναν όλους τους κόμβους
	for nodeidx = 1:length(data.nodes)
		node = data.nodes{nodeidx};
		% Οι τιμές των δεσμευμένων βαθμών ελευθερίας του κόμβου τοποθετούνται στο
		% διάνυσμα των επικόμβιων μετατοπίσεων
		for i = 1:7
			dofidx = node.dofs(i);
			if (dofidx < 0)
				data.solver.displacements2(-dofidx) = node.displacements(i);
			endif
		endfor
		% Απαρίθμηση των επικόμβιων φορτίων του κόμβου, αν υπάρχουν
		if (isfield(node, 'nodalLoads'))
			% Περιλαμβάνει φορτία και αντιδράσεις μαζί. Προς το παρόν, μόνο φορτία.
			data.nodes{nodeidx}.actions = node.nodalLoads;
			for i = 1:7
				el = node.nodalLoads(i);
				if (el)
					dofidx = node.dofs(i);
					if (dofidx > 0)     data.solver.loads1(dofidx) += el;
					elseif (dofidx < 0) data.solver.loads2(-dofidx) += el;
					else	% Αν συνιστώσα της δύναμης υπάρχει σε βαθμό ελευθερίας που δεν υποστηρίζει ο κόμβος
						error(["O κόμβος ", node.id, " δεν έχει το βαθμό ελευθερίας ", ...
								num2str(start + i), " στον οποίο υπάρχει συνιστώσα φορτίου"]);
					endif
				endif
			endfor
		endif
	endfor
endfunction


% ======================================================================= SOLVER


% Επίλυση του φορέα.
% Επιλέγεται μια από τις μεθόδους Conjugate Gradient (χωρίς πολλαπλασιαστές
% Lagrange) ή Conjugate Residuals (με πολλαπλασιαστές Lagrange)
% Αν όλα αποτύχουν (σχεδόν αδύνατο) εφαρμόζεται επίλυση πυκνών πινάκων.
function solveStructure()
	global data;
	% Οι όροι των εξισώσεων Lagrange εισήχθησαν στα μητρώα μόνο ως γραμμές.
	% Ώρα να εισαχθούν και σαν στήλες.
	data.solver.stiffness1(1:data.solver.free, data.solver.free + 1 : data.solver.freeAll) = ...
			data.solver.stiffness1(data.solver.free + 1 : data.solver.freeAll, 1:data.solver.free)';
	% Μέχρι 50 βαθμούς ελευθερίας λύνουμε με την κλασική μέθοδο πυκνών πινάκων
	if (length(data.solver.stiffness1) > 50)
		% Δημιουργία αραιού πίνακα από τον πυκνό
		data.solver.stiffness1 = sparse(data.solver.stiffness1);
		data.solver.stiffness12 = sparse(data.solver.stiffness12);
		data.solver.stiffness2 = sparse(data.solver.stiffness2);
	endif

	% Επίλυση
	%
	% Το μητρώο δυσκαμψίας είναι συμμετρικός θετικά ορισμένος πίνακας, διότι ο φορέας
	% ισορροπεί εκεί που έχουμε ελαχιστοποίηση ενέργειας, άρα ?E=ΣF=0 και ?(?E)=?ΣF=[K]
	% που σημαίνει ότι ο [K] είναι θετικά ορισμένος.
	% Η καλύτερη μέθοδος για επίλυση συμμετρικών θετικά ορισμένων πινάκων είναι η
	% Conjugate Gradient.
	% Όταν όμως προσθέτουμε σχέσεις Φ πολλαπλασιαστών Lagrange στο μητρώο [K], αυτό
	% παραμένει συμμετρικό αλλά παύει να είναι θετικά ορισμένο. ’ρα δεν μπορεί να
	% χρησιμοποιηθεί η Conjugate Gradient.
	A = data.solver.stiffness1;
	b = data.solver.loads1' - data.solver.stiffness12 * data.solver.displacements2';
	% Μέχρι 50 βαθμούς ελευθερίας λύνουμε με την κλασική μέθοδο πυκνών πινάκων
	if (length(b) > 50)
		if (~data.solver.totalLagrangeEquations)
			[data.solver.displacements1, flag, tol, it] = pcg(A, b, 10^-10, 1500);
			switch(flag)
				case 0 data.solver.method = ['Conjugent Gradient: iterations=', num2str(it), ', norm(b-A*x)=', num2str(tol)];
				case 1 warning("Conjugate Gradient: Η επίλυση ξεπέρασε τις προβλεπόμενες επαναλύψεις χωρίς να ελαχιστοποιήσει το σφάλμα κάτω από το απαιτούμενο");
				case 2 error("Conjugate Gradient: Σοβαρό σφάλμα στη μόρφωση του φορέα - το μητρώο δυσκαμψίας Κ11 δεν αντιστρέφεται");
				case 3 warning("Conjugate Gradient: 'Λίμνασε' σε τιμή που δεν είναι η λύση");
				% Λογικά δε θα προκύψει ποτέ η περίπτωση αυτή:
				case 4 warning("Conjugate Gradient: Βρέθηκε μη θετικά ορισμένος πίνακας");
			endswitch
		endif
		% Η καλύτερη μέθοδος (πιο αργή από την Conjugate Gradient) για συμμετρικούς
		% πίνακες είναι η Conjugate Residuals.
		if (data.solver.totalLagrangeEquations || flag)
			[data.solver.displacements1, flag, tol, it] = pcr(A, b, 10^-15, 1500);
			switch(flag)
				case 0 data.solver.method = ['Conjugent Residuals: iterations=', num2str(it), ', norm(b-A*x)=', num2str(tol)];
				case 1 warning("Conjugate Residuals: Η επίλυση ξεπέρασε τις προβλεπόμενες επαναλύψεις χωρίς να ελαχιστοποιήσει το σφάλμα κάτω από το απαιτούμενο");
				case 2 error("Conjugate Residuals: Σοβαρό σφάλμα στη μόρφωση του φορέα - το μητρώο δυσκαμψίας Κ11 δεν αντιστρέφεται");
				case 3 warning("Conjugate Residuals: Breakdown");
			endswitch
		endif
	endif
	% Η χειρότερη μέθοδος είναι η μέθοδος των πυκνών πινάκων
	if (length(b) <= 50 || flag)
		data.solver.method = 'Dense matrix \';
		if (rcond(A) < 65535 * eps) error("Πολύ κακό μητρώο δυσκαμψίας φορέα που ίσως δεν αντιστρέφεται"); endif
		data.solver.displacements1 = A \ b;
	endif
	
	% Πετάμε στα σκουπίδια τις σχέσεις των πολλαπλασιαστών Lagrange
	data.solver.stiffness1 = data.solver.stiffness1(1:data.solver.free, 1:data.solver.free);
	data.solver.stiffness12 = data.solver.stiffness12(1:data.solver.free, :);
	data.solver.displacements1 = data.solver.displacements1'(1:data.solver.free); % Αναστροφή!
	data.solver.loads1 = data.solver.loads1(1:data.solver.free);
	% Υπολογίζουμε τις αντιδράσεις των ελεύθερων βαθμών ελευθερίας.
	% Αυτό γιατί κάποιοι από τους "ελεύθερους" βαθμούς ελευθερίας είναι δεσμευμένοι
	% σε διεύθυνση διαφορετική από τις καθολικές.
	data.solver.reactions1 = data.solver.displacements1 * data.solver.stiffness1 + ...
			data.solver.displacements2 * data.solver.stiffness12' - data.solver.loads1;
	% Υπολογίζουμε τις αντιδράσεις των δεσμευμένων βαθμών ελευθερίας.
	data.solver.reactions2 = data.solver.displacements1 * data.solver.stiffness12 + ...
			data.solver.displacements2 * data.solver.stiffness2 - data.solver.loads2;
endfunction


% ============================================================== POST-PROCESSING


% Τα αποτελέσματα αντιδράσεων - μετατοπίσεων καταγράφονται σε κάθε κόμβο
function outputToNodes()
	global data;
	for nodeidx = 1:length(data.nodes)
		% Αν υπάρχουν αντιδράσεις, θα χρειαστεί και η άθροιση φορτίων-αντιδράσεων
		if (isfield(data.nodes{nodeidx}, 'reactions') && ~isfield(data.nodes{nodeidx}, 'actions'))
			data.nodes{nodeidx}.actions = zeros(1, 7);
		endif
		for dofidx = 1:7
			row = data.nodes{nodeidx}.dofs(dofidx);	% Στήλη του P και δ, για επικόμβιο φορτίο και μετατόπιση
			react = isfield(data.nodes{nodeidx}, 'reactions') && ~isnan(data.nodes{nodeidx}.reactions(dofidx));	% Υπάρχει αντίδραση
			if (row > 0)
				data.nodes{nodeidx}.displacements(dofidx) = data.solver.displacements1(row);
				if (react)
					data.nodes{nodeidx}.reactions(dofidx) = data.solver.reactions1(row);
					data.nodes{nodeidx}.actions(dofidx)  += data.solver.reactions1(row);
				endif
			elseif (row < 0 && react)
				% Οι μετατοπίσεις υπάρχουν ήδη
				data.nodes{nodeidx}.reactions(dofidx) = data.solver.reactions2(-row);
				data.nodes{nodeidx}.actions(dofidx)  += data.solver.reactions2(-row);
			endif
		endfor
	endfor
endfunction

% Τα αποτελέσματα αντιδράσεων - μετατοπίσεων καταγράφονται σε κάθε στοιχείο-μέλος
function outputToElements()
	global data;
	for elementidx = 1:length(data.elements)
		element = data.elements{elementidx};
		% Καταγραφή των μετατοπίσεων των βαθμών ελευθεριών των κόμβων που επηρεάζουν το στοιχείο
		displacements = zeros(1, columns(element.dofs));
		for dofidx = 1:length(displacements)
			dof = element.dofs(:, dofidx);
			row = data.nodes{dof(1)}.dofs(dof(2));
			if (row > 0) displacements(dofidx) = data.solver.displacements1(row);
			else displacements(dofidx) = data.solver.displacements2(-row);
			endif
		endfor
		% Οι μετατοπίσεις σε τοπικό επίπεδο στο στοιχείο, καθώς και οι υπολογισμοί
		% των φορτίσεων του στοιχείου
		data.elements{elementidx}.displacements = displacements = displacements * element.lcsMatrix';
		loads = displacements * element.stiffness;
		if (isfield(element, "loads")) loads -= element.loads; endif
		data.elements{elementidx}.reactions = loads;
	endfor
endfunction

% Εξάγει τον εφελκυσμό/θλίψη, την αξονική και την τάση μιας ράβδου
function outputBarFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'Δx', 'N', 'σ<sub>x</sub>', 'σ<sub>VonMises</sub>'};
	dx = element.displacements(2) - element.displacements(1);	% Δx
	N = -element.reactions(1);								% Αξονική
	sx = N / data.frame_sections{element.section}.A;	% Τάση
	element.function_values = [dx, N, sx, sx];
	data.elements{index} = element;
endfunction

% Εξάγει μετακινήσεις, τάσεις και εντατικά μεγέθη μιας δοκού.
% Δεν εξάγει τίποτα επειδή δεν την ολοκληρώσαμε.
function outputBeamFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'L-th', 'x', 'u<sub>x</sub>', 'u<sub>y</sub>', 'u<sub>z</sub>', ...
			'θ<sub>x</sub>', 'θ<sub>y</sub>', 'θ<sub>z</sub>', 'N', 'V<sub>y</sub>', ...
			'V<sub>z</sub>', 'M<sub>x</sub>', 'M<sub>y</sub>', 'M<sub>z</sub>', 'M<sub>w</sub>', ...
			'σ<sub>xx,max</sub>', 'σ<sub>xy,max</sub>', 'σ<sub>xz,max</sub>', 'σ<sub>yy,max</sub>', ...
			'σ<sub>yz,max</sub>', 'σ<sub>zz,max</sub>', 'σ<sub>VonMises</sub>'};
	if (isfield(element, 'distributed_loads')) P = element.distributed_loads; else P = zeros(2, 6); endif
	slices = 50;
	A = nan(slices + 1, 22);
	A(:, 1) = 0:slices;		% L-th
	A(:, 2) = A(:, 1) * element.L / slices;		% x
	A(:, 9) = (P(2,1) - P(1,1)) / (2 * element.L) * A(:, 2).^2 + P(1,1) * A(:, 2) - element.reactions(1);	% N
	A(:, 10) = (P(2,2) - P(1,2)) / (2 * element.L) * A(:, 2).^2 + P(1,2) * A(:, 2) + element.reactions(2);	% Vy
	A(:, 11) = (P(2,3) - P(1,3)) / (2 * element.L) * A(:, 2).^2 + P(1,3) * A(:, 2) + element.reactions(3);	% Vz
	A(:, 12) = (P(2,4) - P(1,4)) / (2 * element.L) * A(:, 2).^2 + P(1,4) * A(:, 2) + element.reactions(4);	% Mx
	A(:, 13) = (P(2,5) - P(1,5)) / (2 * element.L) * A(:, 2).^2 + P(1,5) * A(:, 2) + element.reactions(5) ...
			+ (P(2,3) - P(1,3)) / (6 * element.L) * A(:, 2).^3 + P(1,3) / 2 * A(:, 2).^2 + element.reactions(3) * A(:, 2);	% My
	A(:, 14) = (P(2,6) - P(1,6)) / (2 * element.L) * A(:, 2) .^2 + P(1,6) * A(:, 2) + element.reactions(6) ...
			- ((P(2,2) - P(1,2)) / (6 * element.L) * A(:, 2).^3 + P(1,2) / 2 * A(:, 2).^2 + element.reactions(2) * A(:, 2));	% Mz
	element.function_values = A;
	data.elements{index} = element;
endfunction

% Εξάγει τη μετακίνηση και τη δύναμη ενός γραμμικού ελατηρίου
function outputLinearSpringFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'Δx', 'F'};
	if (length(element.nodes) == 1) dx = element.displacements(1);
	else dx = element.displacements(2) - element.displacements(1);	% Δx
	endif
	F = -element.reactions(1);
	element.function_values = [dx, F];
	data.elements{index} = element;
endfunction

% Εξάγει τη στροφή και τη ροπή ενός στροφικού ελατηρίου
function outputTorsionSpringFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'Δθ', 'M'};
	if (length(element.nodes) == 1) dx = element.displacements(1);
	else dx = element.displacements(2) - element.displacements(1);	% Δx
	endif
	M = -element.reactions(1);
	element.function_values = [dx, M];
	data.elements{index} = element;
endfunction

% Εξάγει τις συναρτήσεις των στοιχείων π.χ. N(x), Vy(x), u(x) κτλ
% Για κάθε στοιχείο είναι διαφορετικός
function outputElementsFunctions()
	global data;
	for elementidx = 1:length(data.elements)
		switch(data.elements{elementidx}.type)
			case 0 outputBarFunctions(elementidx);
			case 1 outputLinearSpringFunctions(elementidx);
			case 3 outputBeamFunctions(elementidx);
		endswitch
	endfor
endfunction

% ============================================================= ΕΞΑΓΩΓΗ ΑΝΑΦΟΡΑΣ

% Δωσμένου του index ενός DoF επιστρέφει το όνομά του.
% in: i: Το index του DoF από 1 μέχρι 7
% out: i: Το όνομα του DoF από 'disp_x' μέχρι 'warp'
function i = getDoFName(i)
	switch(i)
		case 1 i = 'disp_x';
		case 2 i = 'disp_y';
		case 3 i = 'disp_z';
		case 4 i = 'rot_x';
		case 5 i = 'rot_y';
		case 6 i = 'rot_z';
		case 7 i = 'warp';
		otherwise error(['Δεν υπάρχει DoF με index ', num2str(i)]);
	endswitch
endfunction

% Δωσμένου του index ενός μέλους επιστρέφει τον τύπο του.
% in: i: Το index του μέλους
% out: i: Το όνομα του τύπου του μέλους π.χ. 'Δοκός'
function i = getElementType(i)
	switch(i)
		case 0 i = 'Ράβδος';
		case 1 i = 'Γραμμικό ελατήριο';
		case 2 i = 'Στροφικό ελατήριο';
		case 3 i = 'Δοκός';
		otherwise error(['Δεν υπάρχει τύπος μέλους με index ', num2str(i)]);
	endswitch
endfunction

% Εξαγωγή των αποτελεσμάτων σε έκθεση html
% in: filename: Το όνομα αρχείου εξόδου (html)
function exportReport(filename)
	global data;
	fp = fopen(filename, 'w');
	fwrite(fp, "<html>\r\n");
	fwrite(fp, "<head>\r\n");
	fwrite(fp, "<meta charset=\"UTF-8\">\r\n");
	fwrite(fp, "<title>Αποτελέσματα Ανάλυσης</title>\r\n\r\n");
	fwrite(fp, "<style>\r\n");	% CSS Stylesheets
	fwrite(fp, "table { border-collapse: collapse; }\r\n");
	fwrite(fp, "th, td { border: 1px solid black; }\r\n");
	fwrite(fp, "tbody>tr.even { background-color: #eee; }\r\n");
	fwrite(fp, "tbody>tr:hover { background-color: #cec; }\r\n");
	fwrite(fp, "</style>\r\n");
	fwrite(fp, "</head>\r\n\r\n");
	fwrite(fp, "<body>\r\n\r\n");
	% Εξαγωγή στοιχείων των κόμβων
	fwrite(fp, "<h1>Κόμβοι</h1>\r\n\r\n");
	fwrite(fp, "<table>\r\n<thead>\r\n<tr><th>Κόμβος</th><th>Βαθμός Ελευθερίας</th><th>Παγιωμένη Μετατόπιση</th><th>Αρχική Θέση</th><th>Μετατόπιση</th><th>Τελική Θέση</th><th>Φορτίο</th><th>Αντίδραση</th><th>Δράση</th></tr>\r\n</thead>\r\n<tbody>\r\n");
	for i = 1:length(data.nodes);
		n = data.nodes{i};
		for j = 1:7
			row = n.dofs(j);	% 0: δεν υπάρχει, >0: ελεύθερος, <0: δεσμευμένος
			if (row)
				if (mod(i, 2)) p = '<tr>'; else p = '<tr class="even">'; endif
				fwrite(fp, p);
				fwrite(fp, ['<td>', n.id, '</td>']);
				fwrite(fp, ['<td>', getDoFName(j), '</td>']);
				% Δεσμευμένος βαθμός ελευθερίας
				if (row < 0) p = 'ναι'; else p = 'όχι'; endif
				fwrite(fp, ['<td>', num2str(p), '</td>']);
				% Αρχική θέση βαθμού ελευθερίας, μετακίνηση και τελική θέση
				if (j <= 3) p = num2str(n.coords(j)); else p = ''; endif
				fwrite(fp, ['<td>', p, '</td>']);
				p = num2str(n.displacements(j));	% Χρησιμοποιείται και στην τελική θέση
				fwrite(fp, ['<td>', p, '</td>']);
				if (j <= 3) p = num2str(n.coords(j) + n.displacements(j)); endif
				fwrite(fp, ['<td>', p, '</td>']);
				% Επικόμβια φορτία δίχως αντιδράσεις, αντιδράσεις και άθροισμα αυτών
				if (isfield(n, 'nodalLoads') && n.nodalLoads(j)) p = num2str(n.nodalLoads(j)); else p = ''; endif
				fwrite(fp, ['<td>', p, '</td>']);
				if (isfield(n, 'reactions') && ~isnan(n.reactions(j))) p = num2str(n.reactions(j)); else p = ''; endif
				fwrite(fp, ['<td>', p, '</td>']);
				if (isfield(n, 'actions') && n.actions(j)) p = num2str(n.actions(j)); else p = ''; endif
				fwrite(fp, ['<td>', p, '</td>']);
				fwrite(fp, "</tr>\r\n");
			endif
		endfor
	endfor
	fwrite(fp, "</tbody>\r\n</table>\r\n\r\n");
	% Εξαγωγή στοιχείων των μελών
	fwrite(fp, "<h1>Μέλη</h1>\r\n\r\n");
	for i = 1:length(data.elements);
		n = data.elements{i};
		fwrite(fp, ['<h2>', getElementType(n.type), ' ', n.id, "</h2>\r\n"]);
		fwrite(fp, "<table>\r\n<thead>\r\n<tr>");
		for j = n.functions
			j = j{1};
			fwrite(fp, ['<th>', j, '</th>']);
		endfor
		fwrite(fp, "</tr>\r\n</thead>\r\n<tbody>\r\n");
		for k = n.function_values'
			fwrite(fp, '<tr>');
			for j = k';
				fwrite(fp, ['<td>', num2str(j), '</td>']);
			endfor
			fwrite(fp, "</tr>\r\n");
		endfor
		fwrite(fp, "</tbody>\r\n</table>\r\n\r\n");
	endfor
	fwrite(fp, "</body>\r\n</html>");
	fclose(fp);
endfunction


% ============================================= Ο ΚΥΡΙΟΣ ΚΟΡΜΟΣ ΤΟΥ ΠΡΟΓΡΑΜΜΑΤΟΣ


try

	% Φορτώνει το αρχείο xml με το φορέα
	[file, path] = uigetfile('*.xml', 'Δώστε το αρχείο XML του φορέα');
	if (~file) return; endif;
	parseXML([path, file]);
	% Υπολογίζει τις ιδιότητες G του υλικού
	calcMaterialProperties();
	% Υπολογίζει τις ιδιότητες A, Iy, Iz, It, Cs της διατομής
	calcFrameSectionsProperties();
	% Καταχωρεί τα επικόμβια φορτία στους κόμβους
	calcNodalLoads();
	% Υπολογίζει τα μητρώα δυσκαμψίας των στοιχείων καθώς και τυχόν αρχικές εντάσεις
	% Ενημερώνει τους κόμβους για τους DoFs που επηρρεάζονται
	calcElementsStiffness();

	%{
	Το μητρώο δυσκαμψίας του φορέα περιγράφεται παρακάτω.
	+---+---+---+
	¦K11¦K12¦K13¦
	+---+---+---+
	¦K21¦ 0 ¦K23¦
	+---+---+---+
	¦K31¦K32¦K33¦
	+---+---+---+
	Κ11: Οι ελεύθεροι βαθμοί ελευθερίας του φορέα.
	Κ33: Οι δεσμευμένοι βαθμοί ελευθερίας του φορέα.
	K13: Η μικτή κατάσταση.
	Κ31: Ο ανάστροφος του Κ13. Δεν δημιουργείται. Χρησιμοποιείται ο K13' στη θέση του.
	Κ21: Τα μερικά διαφορικά ως προς τους ελεύθερους βαθμούς ελευθερίας του φορέα,
				των σχέσεων Φ των πολλαπλασιαστών Lagrange.
	Κ23: Τα μερικά διαφορικά ως προς τους δεσμευμένους βαθμούς ελευθερίας του φορέα,
				των σχέσεων Φ των πολλαπλασιαστών Lagrange.
	Κ12: Ο ανάστροφος του Κ21. Τοποθετείται αφού υπολογιστεί ο Κ21.
	Κ32: Ο ανάστροφος του Κ23. Δεν δημιουργείται. Χρησιμοποιείται ο Κ32' στη θέση του.
	0: Μηδενικός πίνακας.
	Κ11,Κ12,Κ21,0: Οι ελεύθεροι βαθμοί ελευθερίας του φορέα, μαζί με τις σχέσεις
				πολλαπλασιαστών Lagrange.
	K13,K23:
	%}

	% Πόσες εξισώσεις πολλαπλασιαστών Lagrange θα προστεθούν στα μητρώα
	data.solver.totalLagrangeEquations = 0;
	% Μετατροπή των restraints σε constraints, που είναι η πιο γενικευμένη μορφή
	convertRestraintsToConstraints();
	%Επεξεργασία των constraints
	linkConstrainedDoFs();
	% Δημιουργεί τα διανύσματα αναδιάταξης με indices 1,2,3,.. για τους ελεύθερους
	% βαθμούς ελευθερίας και -1,-2,-3,... για τους δεσμευμένους.
	makePermutationLookupTableOnNodes();
	% Δημιουργεί τους 3 πίνακες του μητρώου δυσκαμψίας του φορέα, καθώς και τα διανύσματα
	initStructureStiffness();
	% Συμπληρώνει τους 3 πίνακες του μητρώου δυσκαμψίας του φορέα, ΜΟΝΟ από τα στοιχεία
	populateStructureStiffnessFromElements();
	% Συμπληρώνει τα επικόμβια διανύσματα (φορτία και μετατοπίσεις) από τους κόμβους
	populateStructureStiffnessFromNodes();
	% Ενσωματώνει στα μητρώα δυσκαμψίας του φορέα, τις εξισώσεις πολλαπλασιαστών
	% Lagrange των εξαναγκασμών (constraints)
	populateStructureStiffnessFromConstraints();
	% Κατόπιν ο φορέας επιλύεται
	solveStructure();
	% Οι κόμβοι ενημερώνονται για τις μετατοπίσεις στους βαθμούς ελευθερίας και
	% τις αντιδράσεις των δεσμεύσεων
	outputToNodes();
	% Τα στοιχεία ενημερώνονται για τις μετατοπίσεις στους τοπικούς βαθμούς ελευθερίας
	% και τα φορτία των κόμβων
	outputToElements();
	% Εξειδικευμένος κώδικας για κάθε στοιχείο που εξάγει τις συναρτήσεις των στοιχείων
	% σε πίνακες
	outputElementsFunctions();
	% Επιλογή αρχείου εξόδου
	[file, path] = uiputfile('*.html', 'Δώστε το αρχείο αποθήκευσης των αποτελεσμάτων', path);
	if (~file) file = "export.html"; endif;
	exportReport([path, file]);
	%exportFigures(data);

catch err
	opt.Interpreter = 'none'; opt.WindowStyle = 'modal';
	errordlg(err.message, "Σφάλμα", opt);
	error(err);
end_try_catch;