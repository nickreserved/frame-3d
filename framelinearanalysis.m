% � ����� ���� ��������� ��� ������������ ����� ���������� ��� ������
global data;

% =================================================================== XML PARSER


% �� Octave ������� �� ���������� Apache Xerces ��� �� ��������, �����������
% ��� ����� ������� �������, ������ xml.
% � ���������� ��� ������� ��� Octave. � ������� ������ �� ��� ���������.
javaaddpath("xercesImpl-2.12.0-sp1.jar");
javaaddpath("xml-apis-ext-1.3.04.jar");
% �� Octave ������� �� io ������ ��� �� ��������, ����������� ��� ����� �������
% �������, ������ xml.
% ��� ��� ����������� ��� ��������� ��� ������ `pkg install -forge io`
pkg load io;

% ������� �� ��� xml element ���� �� ����� ��� �������.
% in: node: xml element ��� ������
% in: name: �� ����� ��� ������� �� ���� �� xml element
% error: �� ��� ���� �� ����� ��� �������
function parseCheckElementName(node, name)
	if ~strcmp(node.getNodeName, name)
		error(["����������� ", name, " element, ������� ", node.getNodeName]);
	endif;
endfunction

% �� ������� ����� ������ xml �����
% in: str �� �������
% out: is �� ������� ����� ������ xml �����, ��������� ��� @id
function is = isXmlName(str)
	is = ~isempty(regexp(str, '^[A-Za-z_�-��-��-��-������][\w-.]*$'));
endfunction

% ������� ������� ���� xml element �� ����� material
% in: node: �� xml element ��� ������.
% out: material: Octave ���� ������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function material = parseMaterial(node)
	parseCheckElementName(node, "material");
	material.id = node.getAttribute("id"); % �� material@id ����� �����������
	% ������� ��� Young
	material.E = str2num(node.getAttribute("E"));
	if (length(material.E) ~= 1 || material.E <= 0)
		error(["material �� �� ������ @E=", num2str(material.E)]);
	endif;
	% ����� Poisson
	v = str2num(node.getAttribute("v"));
	if (length(v))
		if (length(v) ~= 1 || v <= 0 || v > 0.5)
			error(["material �� �� ������ @v=", num2str(v)]);
		endif;
		material.v = v;
	endif
endfunction

% ������� ������� ���� xml element "O"
% in: node: �� xml element ��� ��������.
% out: section: Octave ���� ��������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function section = parseFrameSectionO(node)
	section.diameter = str2num(node.getAttribute("diameter"));
	if (length(section.diameter) == 1)
		if (section.diameter < 0)
			error(["������ frame_section@diameter > 0, ������ ", num2str(section.diameter), " > 0"]);
		endif;
	elseif (length(section.diameter) == 2)
		if (section.diameter(1) <= section.diameter(2) || section.diameter(2) < 0)
			error(["������ 0 <= frame_section@diameter(2) < frame_section@diameter(1), ������ 0 < ", ...
					num2str(section.diameter(2)), " < ", num2str(section.diameter(1))]);
		endif;
	else
		error(["� ������� ��������� ������ �� ����� ���� (��������) � ��� (���������� - ����������). �������� ", ...
				num2str(length(section.diameter))]);
	endif
endfunction

% ������� ������� ���� xml element "generic"
% in: node: �� xml element ��� ��������.
% out: section: Octave ���� ��������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function section = parseFrameSectionGeneric(node)
	A = str2num(node.getAttribute("A"));
	if (length(A))
		if (length(A) > 1 || A <= 0) error(["������ generic@Iy > 0, ������ ", num2str(Iy), " > 0"]); endif
		section.A = A;
	endif
	Iy = str2num(node.getAttribute("Iy"));
	if (length(Iy))
		if (length(Iy) > 1 || Iy <= 0) error(["������ generic@Iy > 0, ������ ", num2str(Iy), " > 0"]); endif
		section.Iy = Iy;
	endif
	Iz = str2num(node.getAttribute("Iz"));
	if (length(Iz))
		if (length(Iz) > 1 || Iz <= 0) error(["������ generic@Iz > 0, ������ ", num2str(Iz), " > 0"]); endif
		section.Iz = Iz;
	endif
	It = str2num(node.getAttribute("It"));
	if (length(It))
		if (length(It) > 1 || It <= 0) error(["������ generic@It > 0, ������ ", num2str(It), " > 0"]); endif
		section.It = It;
	endif
	Cs = str2num(node.getAttribute("Cs"));
	if (length(Cs))
		if (length(Cs) > 1 || Cs <= 0) error(["������ generic@Cs > 0, ������ ", num2str(Cs), " > 0"]); endif
		section.Cs = Cs;
	endif
	It_S = str2num(node.getAttribute("It_S"));
	if (length(It_S))
		if (length(It_S) > 1 || It_S <= 0) error(["������ generic@It_S > 0, ������ ", num2str(It_S), " > 0"]); endif
		section.It_S = It_S;
	endif
	ay = str2num(node.getAttribute("ay"));
	if (length(ay))
		if (length(ay) > 1 || ay < 1) error(["������ generic@ay > 1, ������ ", num2str(ay), " > 1"]); endif
		section.ay = ay;
	endif
	az = str2num(node.getAttribute("az"));
	if (length(az))
		if (length(az) > 1 || az < 1) error(["������ generic@az > 1, ������ ", num2str(az), " > 1"]); endif
		section.az = az;
	endif
endfunction

% ������� ������� ���� xml element �� ����� frame_section
% in: node: �� xml element ��� ��������.
% out: section: Octave ���� ��������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function section = parseFrameSection(node)
	type = node.getNodeName;
	switch(type)
		case "O" 				section = parseFrameSectionO(node);
		case "generic"	section = parseFrameSectionGeneric(node);
		otherwise error(['�� ��������������� ����� �������� ', type]);
	endswitch;
	section.type = type;
	section.id = node.getAttribute("id"); % �� section@id ����� �����������
endfunction

% ������������� ���� ������� ��� ����������� ��� ������� ��������� �� ����
% in: str: ������� ��� �������� ������������� ���������� �� ����.
% out: coords: �� ������������� ��� �������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
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
			error(["�� ������������� ������ �� ����� 2 � 3 ��� �������� ", num2str(length(coords))]);
		elseif (length(coords) == 2) coords(3) = 0;    % �������� 3�� �������������
		endif
	endif
endfunction

% ������ ������� ������������� ��� ���������� ��� ������� ��������� �� ����
% in: str: ������� ��� �������� ������������� ������ ��� ���������� ���������� �� ����.
% out: lcs: � ������� ��� ������� ���������� ������������� � empty �� ��� �������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function lcs = parseCoordinateSystem(str)
	lcs = str2num(str);
	if (length(lcs) == 6)    % 3d ������ ������� �������������
		x = lcs(1:3);
		y = lcs(4:6);
		n = norm(x);
		if (~n) error("�������� �������� ����� x �� ������ ������� �������������"); endif
		x /= n;
		n = norm(y);
		if (~n) error("�������� �������� ����� y �� ������ ������� �������������"); endif
		y /= n;
		z = cross(x, y);
		n = norm(z);
		if (n < 0.02)
			error(["�� �������� ��� ����� y ������ �� ���� ����� ����������� 1.145� �� ��� ����� x �� ������ ������� �������������: y=", ...
								num2str(y), " �xy=", num2str(asin(n * 180 / pi)), "�"]);
		endif
		z /= n;
		y = cross(z, x);
		lcs = [x; y; z];
	elseif (length(lcs) == 2) % 2d ������ ������� ������������� ��� �� ����� 3d
		n = norm(lcs);
		if (~n) error("�������� �������� ����� x �� ������ ������� �������������"); endif
		lcs /= n;
		lcs(3) = 0;
		z = [0, 0, 1];
		lcs = [lcs; cross(z, lcs); z];
	else
		error(["��� ������� ������������� �������� ��� 6 � 2 ���������� ��� �������� ", ...
				num2str(length(lcs))]);
	endif
endfunction

% ������� ������� ���� xml element ��� �������� ������ (�.�. force � moment)
% in: node: �� xml element ��� ���������.
% out: load: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function load = parseLoad(node)
	% ����� ������ � ����;
	str = node.getNodeName;
	switch(str)
		case "force" load.force = true;
		case "moment" load.force = false;
		otherwise error(["�� ������ ������ �� ����� � force � moment ��� �������: ", str]);
	endswitch
	load.id = node.getAttribute("id"); % �� node@id ����� �����������
	load.coords = parseCoords(node.getAttribute("direction"));	% ���������� �������
	n = norm(load.coords);
	if (~n) error("�������� �������� ����������� �������"); endif
	% �� ����� ��� ������� (�����������)
	% � ������ ����� �� ������� ��� ���������� ��� ������ ������ ���� �� ��� �������� �� ������� ���
	% ��������� �� ������� �� ����� ��� �������. �� ������������, � ���������� ��� ������� ������������
	% �� �����
	if (node.hasAttribute("magnitude"))
		magnitude = str2num(node.getAttribute("magnitude"));
		switch(length(magnitude))
			case 1
				load.coords *= magnitude / n;
			case 2	% ������������ ������ �� �������� ���������
				load.coords /= n;
				load.magnitude = magnitude;
			otherwise
				error(["�� ������� ������� ����� �����������, ��� ������� �� ������: ", num2str(magnitude)]);
		endswitch
	endif
	% �� ������ ����������� �� ������� ������������� ������ � ��������
	% ����� ���� ���� (��������). �� ������� ���������.
	load.lcs = true;	% default ����
	if (node.hasAttribute("coordinate_system"))
		str = node.getAttribute("coordinate_system");
		switch(str)
			case "global"
				load.lcs = false;
			case "local"
			otherwise
				error(["�� ������� ������������� ��� ������� ����� � global � local, ��� �������: ", str]);
		endswitch
	endif
endfunction

% ���������� �� index ���� ��������� ��� ��� ���������� ������ ���������
% in: m: �� ����� (@id) � �� index ��� ��� �������� ���� ������ ���������.
% in: what: �� ����� ��� ������ ��������� �.�. "section" � "material" � "load" � "node".
% out: idx: �� index ��� ��������� ���� ����� ���������.
function idx = getItemIndexFromData(m, what)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	whats = [what, "s"];
	if (isnumeric(m)) idxd = m; state = true;
	else [idxd, state] = str2num(m);
	endif
	idx = uint32(idxd);
	if (~state)
		if (isfield(data.map.(whats), m))
			idx = data.map.(whats).(m);
		else
			error(["��������� ������� �� ����� ", what, ": ", m]);
		endif
	elseif (length(idx) ~= 1 || idx > length(data.(whats)) || idx != idxd)
		error(["��������� ������� �� index ", what, ": ", num2str(m)]);
	endif
endfunction

% ���������� ��� �������� ��� ��� ���������� ������ ���������
% in: m: �� ����� (@id) � �� index ��� ��� �������� ���� ������ ���������.
% in: what: �� ����� ��� ������ ��������� �.�. "section" � "material" � "load" � "node".
% out: item: �� �������� ��� ��� ����� ���������.
function item = getItemFromData(m, what)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	item = data.([what, "s"]){getItemIndexFromData(m, what)};
endfunction

% ���������� ����� �� �� indices ��������� ��� ��� ���������� ������ ���������
% in: m: �� ������� (@id) � �� indices ��� ��� ������ ��������� ���� ������ ���������.
% in: what: �� ����� ��� ������ ��������� �.�. "section" � "material" � "load" � "node".
% out: idx: ����� �� �� indices ��� ��������� ���� ����� ���������.
function idx = getItemsIndicesFromData(m, what)
	n = strsplit(m, " ");
	idx = [];
	for i = n
		idx = [idx, getItemIndexFromData(i{1}, what)];
	endfor
endfunction

% ���������� �� �������� ��� ��� ���������� ������ ���������
% in: m: �� ������� (@id) � �� indices ��� ��� ������ ��������� ���� ������ ���������.
% in: what: �� ����� ��� ������ ��������� �.�. "section" � "material" � "load" � "node".
% out: items: ����� �� �� �������� ���� ����� ���������.
function items = getItemsFromData(m, what)
	n = strsplit(m, " ");
	items = {};
	for i = n
		items{length(items) + 1} = getItemFromData(i{1}, what);
	endfor
endfunction

% ������� ������� ���� xml element �� ����� node
% in: node: �� xml element ��� ������.
% out: nodE: Octave ���� ������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function nodE = parseNode(node)
	global data;
	parseCheckElementName(node, "node");
	nodE.id = node.getAttribute("id");			% �� node@id ����� �����������
	% ������������� ������. ��������� � ������������� ��� �����.
	% ������������� ��� ����� ���� ������ �.�. ��������� ����������.
	b1 = node.hasAttribute("coords"); b2 = node.hasAttribute("clone_coords");
	if (b1 && b2 || ~b1 && ~b2)
		error("� node ������ �� ���� ������� ��� ��� @coords ��� @clone_coords");
	end
	if (node.hasAttribute("coords"))
		nodE.coords = parseCoords(node.getAttribute("coords"));	% ������������� ������
	else
		nodE.coords = getItemFromData(node.getAttribute("clone_coords"), "node").coords;
	endif
	% ��������� ������
	if (node.hasAttribute("loads"))
		loads = getItemsIndicesFromData(node.getAttribute("loads"), "load");
		for i = loads
			if (isfield(data.loads{i}, "magnitude"))
				error(["��������� �� ��������� ������������ ������ ", num2str(i), " �� �����"]);
			endif
		endfor
	else loads = [];
	endif
	if (node.hasAttribute("clone_loads"))
		loads = [loads, getItemFromData(node.getAttribute("clone_loads"), "node").loads];
	endif
	if (length(loads)) nodE.loads = loads; endif;
endfunction

% ������ ������� �������� �������� ����������� ���������
% ��� parseBar() ��� parseBeam()
function element = parsePrismaticCommon(node)
	element.material = getItemIndexFromData(node.getAttribute("material"), "material");
	element.section = getItemIndexFromData(node.getAttribute("section"), "frame_section");
	element.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (length(element.nodes) ~= 2)
		error(["� ����� ���� 2 �������, �������� ", num2str(length(element.nodes))]);
	endif
	if (node.hasAttribute("initial_loads"))
		element.initial_load = str2num(node.getAttribute("initial_loads"));
	endif
endfunction

% ������� ������� ���� xml element �� ����� bar
% in: node: �� xml element ��� ���������.
% out: element: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function element = parseBar(node)
	element = parsePrismaticCommon(node);
	element.type = uint16(0);	% bar type
	% ������� ��� ������������ �� ����� ��� ���� ����
	if (isfield(element, "initial_load"))
		if (length(element.initial_load) ~= 1)
			error(["� ������ ���� ��� ���� ��� ����������, �������� ", ...
					num2str(length(element.initial_load))]);
		endif
	endif
endfunction

% ������� ������� ���� xml element �� ����� beam
% in: node: �� xml element ��� ���������.
% out: element: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function element = parseBeam(node)
	element = parsePrismaticCommon(node);
	element.type = uint16(3);	% beam type
	% ������� ��� ������������
	if (isfield(element, "initial_load"))
		switch(length(element.initial_load))
			case 3 element.initial_load = [element.initial_load(1:2) 0 0 0 element.initial_load(3) 0];
			case 6 element.initial_load(7) = 0;
			case 7
			otherwise
				error(["� ����� ������ �� ���� 3, 6 � 7 ����� ��� ����������, �������� ", ...
						num2str(length(element.initial_load))]);
		endswitch
	endif
	% ��������� z
	if (node.hasAttribute("z_axis"))
		element.axisZ = parseCoords(node.getAttribute("z_axis"));
		n = norm(element.axisZ);
		if (~n) error("� ��������� beam@z_axis ������� ��������"); endif
		element.axisZ /= n;
	endif
	% ������������ ������
	if (node.hasAttribute("distributed_loads"))
		element.distributed_loads = getItemsIndicesFromData(node.getAttribute("distributed_loads"), "load");
	endif
	% ���������
	element.warp = false;
	if (node.hasAttribute("warp"))
		w = node.getAttribute("warp");
		switch(w)
			case "yes" element.warp = true;
			case "no"
			otherwise error(["� ����� �� ���� @warp ������ �� ����� yes � no, �������: ", w]);
		endswitch
	endif
endfunction

% ������� ������� ���� xml element �� ����� spring
% in: node: �� xml element ��� ���������.
% out: element: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function element = parseSpring(node)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	type = node.getAttribute("type");
	switch(type)
		case, "linear"
			element.type = uint16(1);		% linear spring type
		case "torsion"
			element.type = uint16(2);		% torsion spring type
		otherwise
			error(["�� �������� ������ ���� @type linear � torsion, ������� ", type]);
	endswitch
	element.K = str2num(node.getAttribute("K"));
	if (length(element.K) ~= 1)
		error(["�� �������� ���� ��� ������� �, �������� ", num2str(length(element.K))]);
	endif
	element.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (length(element.nodes) ~= 1 && length(element.nodes) ~= 2)
		error(["�� �������� ���� 1 � 2 �������, �������� ", num2str(length(element.nodes))]);
	endif
	% @direction: �� ������� � ����� �������� �������� � ����� �������� ��� �� 2 ������ �����������.
	% �������� � ���������� ����� ��� ��� ����� ��� ������� �����.
	if (length(element.nodes) == 2)
		element.direction = data.nodes(element.nodes(2)).coords - data.nodes(element.nodes(1)).coords;
		n = norm(element.direction);
	endif
	if (node.hasAttribute("direction") || length(element.nodes) == 1 || element.type == 2 || ~n)
		element.direction = parseCoords(node.getAttribute("direction"));
		n = norm(element.direction);
		if (~n) error("�������� �������� ����������� ���������"); endif
	endif
	element.direction /= n;	% ���������
	if (node.hasAttribute("initial_loads"))
		element.initial_load = str2num(node.getAttribute("initial_loads"));
		if (length(element.initial_load) ~= 1)
			error(["�� �������� ���� ��� ���� ��� ����������, �������� ", ...
				num2str(length(element.initial_load))]);
		endif
	endif
endfunction

% ������� ������� ���� xml element ��� ����� �������� ������������ ���������
% in: node: �� xml element ��� ���������.
% out: element: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function element = parseElement(node)
	% ����������� ��������� �� ���� ��� ���� ���
	switch(node.getNodeName)
		case "bar"		element = parseBar(node);
		case "spring"	element = parseSpring(node);
		case "beam"		element = parseBeam(node);
		otherwise			error(["�� ��������������� ����� ���������: ", node.getNodeName]);
	endswitch
	element.id = node.getAttribute("id"); % �� node@id ����� �����������
endfunction

% ������� ������� ���� xml attribute ��� ����� �������� ���� ��� ���� DoF
% ������ �� ����� "yes", "no", ������� � �� ������������.
% �� � DoF ����� �����������, ��� ����� restraint.dofs ��������� �� �������
% index ��� DoF ��� ��� ���� ��� ���������.
% in: node: �� xml element ��� ���������.
% in: name: �� ����� ��� xml attribute ��� DoF.
% in/out: restraint: �� ����������� ��� ���������.
% in: index: �� index ��� DoF ���� �����. �.�. � disp_y ����� 2.
function restraint = parseRestraintDOF(node, name, restraint, index)
	if (~node.hasAttribute(name)) return; endif
	c = node.getAttribute(name);
	switch(c)
		case "no" return;
		case "yes" a = 0;
		otherwise
			a = str2num(c);
			if (length(a) ~= 1) error(["�� �������� ���� ��������� ", name, ": ", c]); endif
	endswitch
	% ���������� ���� �� ��������� format ����� � for ��������� ������(!) ���� ��� �������
	restraint.dofs = [restraint.dofs, [index; a]];
endfunction

% ������� ������� ���� xml element ��� ����� ������������� (�������)
% in: node: �� xml element ��� ���������.
% out: restraint: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function restraint = parseRestraint(node)
	parseCheckElementName(node, "restraint");
	restraint.id = node.getAttribute("id"); % �� node@id ����� �����������
	restraint.nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	if (~length(restraint.nodes)) error("� �������� ������ �� ���� ����������� ��� �����"); endif
	% ������ ������� ������������� (�����������)
	if (node.hasAttribute("local_coordinate_system"))
		restraint.lcs = parseCoordinateSystem(node.getAttribute("local_coordinate_system"));
	endif
	% ���������� ������ ����������
	restraint.dofs = [];
	restraint = parseRestraintDOF(node, "disp_x", restraint, 1);
	restraint = parseRestraintDOF(node, "disp_y", restraint, 2);
	restraint = parseRestraintDOF(node, "disp_z", restraint, 3);
	restraint = parseRestraintDOF(node, "rot_x", restraint, 4);
	restraint = parseRestraintDOF(node, "rot_y", restraint, 5);
	restraint = parseRestraintDOF(node, "rot_z", restraint, 6);
	restraint = parseRestraintDOF(node, "warp", restraint, 6);
endfunction

% ������� ������� ���� xml element ��� ����� ������������
% in: node: �� xml element ��� ���������.
% out: constraint: Octave ���� ���������.
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function constraint = parseConstraint(node)
	parseCheckElementName(node, "constraint");
	constraint.id = node.getAttribute("id"); % �� node@id ����� �����������
	% ������ ������� ������������� (�����������)
	if (node.hasAttribute("local_coordinate_system"))
		constraint.lcs = parseCoordinateSystem(node.getAttribute("local_coordinate_system"));
	endif
	% ������� ��� ������ ��� DoF
	nodes = getItemsIndicesFromData(node.getAttribute("nodes"), "node");
	ii = length(nodes);
	if (~ii) error("� �������� ������ �� ���� ����������� ��� �����"); endif
	% ��������� ���� ��� DoFs �� ��������� �� ���� ������� ����
	dofs = strsplit(node.getAttribute("dofs"), " ");
	i = 1;	% index ���� ���������� ����� ��� �� �������� ��� ����
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
					error(["� �������� ���� DoFs ��� ������������� ������� ��� ���� ", num2str(ii), " ��� ��������"]);
				endif
			otherwise error(["������� �� ������ ����� ������ ����������: ", dof{1}]);
		endswitch
	endfor
	if (isempty(constraint.dofs)) error("� �������� ������ �� ������������ ����������� ��� ����� ����������"); endif
	% �� �� DoFs �������� ���� ��� ���� ��� ����� ���� �������, ��������� ����
	if (i == 1)
		j = columns(constraint.dofs);
		dofs = constraint.dofs;
		for i = 2:ii
			dofs(1, :) = nodes(i);
			constraint.dofs = [constraint.dofs, dofs];
		endfor
	endif
	% ������� ��� ������ � (����������� ��� DoFs)
	% ����� ��� #text
	if (~isempty(node.getFirstChild) && node.getFirstChild.getNodeType == 3) # TEXT_NODE
		i = columns(constraint.dofs) + 1;
		nums = str2num(node.getFirstChild.getNodeValue);
		j = length(nums);
		if (mod(j, i))
			error(["��� ", num2str(i - 1), " ������������ ������� ���������� ��� ��� ������, ������ ��������� ����������� ��� ", ...
					num2str(i), ", �������� ", num2str(j)]);
		endif
		% � ������� ������� ������ ��� ������������
		constraint.disp_eq = reshape(nums, i, j / i)';
		constraint.disp_const = constraint.disp_eq(:, i)';
		constraint.disp_eq(:, i) = [];
	endif
endfunction

% ������� ������� ���� ������ ������������ ��� xml, �.�. materials � nodes
% in: node: �� xml element ��� ������ ��� ������� �������
% in: name: �� ����� ��� ������ �� ���� �� xml element ��� ������.
% ��� ������� ������� �� �� node ���� ���� �� �����.
% in: func: ��� ��������� ������������ ��� �������� xml element ��� xml element
% ��� ������
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function parseGroupOfNoCheck(node, name, func)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	child = node.getFirstElementChild;
	data.(name) = {};
	while ~isempty(child)
		try
			newIdx = length(data.(name)) + 1;
			item.id = num2str(newIdx);		% ������������ ��������� ��� �� error handling
			item = func(child);
			% ������� ����������� id
			if (length(item.id))
				if (~isXmlName(item.id)) error(["�� ������ ������� ��� �� @id=", item.id]); endif
				data.map.(name).(item.id) = newIdx;	% ���������� �� ��������� ������� ��������
			else
				item.id = num2str(newIdx);		% ������ �� id ����� � ����� �������
			endif
			% ���������� �� ����������
			data.(name){newIdx} = item;
			child = child.getNextElementSibling;
		catch err
			err.message = ["�������� ��� ���������� ", name, ", ��� �������� ", item.id, "\n", err.message];
			error(err);
		end_try_catch
	endwhile
endfunction

% ������� ������� ���� ������ ������������ ��� xml, �.�. materials � nodes
% in: node: �� xml element ��� ������ ��� ������� �������
% in: name: �� ����� ��� ������ �� ���� �� xml element ��� ������.
% �� ��� ���� ���� �� ����� ����� ������.
% in: func: ��� ��������� ������������ ��� �������� xml element ��� xml element
% ��� ������
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function parseGroupOf(node, name, func)
	parseCheckElementName(node, name);
	parseGroupOfNoCheck(node, name, func);
endfunction

% ������� ������� ���� ������ ������������ ��� xml, �.�. materials � nodes
% in: node: �� xml element ��� ������ ��� ������� �������
% in: name: �� ����� ��� ������ �� ���� �� xml element ��� ������.
% �� ��� ���� ���� �� ����� ��� ���������� ������.
% in: func: ��� ��������� ������������ ��� �������� xml element ��� xml element
% ��� ������
% out: parsed: true �� � ���������� ������
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
function parsed = parseGroupOfIfExist(node, name, func)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	if (~isempty(node) && strcmp(node.getNodeName, name))
		parseGroupOfNoCheck(node, name, func);
		parsed = true;
	else data.(name) = {}; data.map.(name) = {}; parsed = false;
	endif
endfunction

%{
function parsed = parseOutputOptionsIfExist(library)
	global data;	% �� �������� ��� �����, ���� ����� �������� ����� ����.
	solverDefaultSettings();
	if (~isempty(node) && strcmp(node.getNodeName, "output-options"))
		child = node.getFirstElementChild;
		% solver parsing
		if (~isempty(child) && strcmp(child.getNodeName, "solver"))
			b = child.getAttribute("tolerance");
			a = str2num(b);
			if (length(a))
				if (length(a) ~= 1 || a < 10^-15 || a > 10^-2)
					error(["Conjugent Gradient/Residuals tolerance ������ �� ����� 10^-15 �� 10^-2, ������� ", b]);
				endif
				data.solver.settings.tolerance = a
			endif
			b = child.getAttribute("iterations");
			a = uint32(str2num(b));
			if (length(a))
				if (length(a) ~= 1 || ~a)
					error(["Conjugent Gradient/Residuals ������ ������ �� ����� ��� 1 ��� ����, ������� ", b]);
				endif
				data.solver.settings.iterations = a
			endif
			b = child.getAttribute("min-reaction");
			a = str2num(b);
			if (length(a))
				if (length(a) ~= 1 || ~a)
					error(["Conjugent Gradient/Residuals ������ ������ �� ����� ��� 1 ��� ����, ������� ", b]);
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

% �������� �� ������ xml ��� �����
% in: xml: �� ����� ������� ��� ������� xml
% error: ������ ���� ��� ������� ������� � �� ������ ��������.
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
		err.message = ["�������� ���� ��� ������� ��� ������� xml\n", err.message];
		error(err);
	end_try_catch;
endfunction;


% =============================================================== PRE-PROCESSING


% ���������� �� �������������� G ��� ������
function calcMaterialProperties()
	global data;
	for i = 1:length(data.materials)
		if (isfield(data.materials{i}, "v"))
			data.materials{i}.G = data.materials{i}.E / 2 / (1 + data.materials{i}.v);
		endif
	endfor
endfunction

% ���������� �� �������������� A, Iy, Iz, It, Cs �������� ����� �,
% ���� �� �� ���������� ����� �� ����� ��������
% in,out: section: � ������� ��������
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

% ���������� �� �������������� A, Iy, Iz, It, Cs ��� ��������,
% ���� �� �� ���������� ����� �� ����� ��������
% in,out: section: � ������� ��������
function calcFrameSectionsProperties()
	global data;
	for i = 1:length(data.frame_sections)
		switch(data.frame_sections{i}.type)
			case "O"
				data.frame_sections{i} = calcFrameSection_O_Properties(data.frame_sections{i});
			case "generic"	% ����� ��� ������������
			%TODO: ������ ��������
		endswitch
	endfor
endfunction

% ����������� �� ��������� ������ ��� ������
function calcNodalLoads()
	global data;
	% ��������� ���� ���� ����� ���� �������
	for nodeidx = 1:length(data.nodes)
		node = data.nodes{nodeidx};
		% ���������� ��� ���������� ������� ��� ������, �� ��������
		if (isfield(node, "loads"))
			data.nodes{nodeidx}.nodalLoads = zeros(1,7);
			for loadidx = node.loads
				load = data.loads{loadidx};
				% �� ����� ������ �������� ��� �� ����� ���������� 1, ���� ��� ��� 4
				if (load.force) start = 1; else start = 4; endif
				data.nodes{nodeidx}.nodalLoads(start:start+2) += load.coords;
			endfor
		endif
	endfor
endfunction

% ������� ����������� ������� ���������� ��� ��� ��������
% - ������� ��� ��������� �������/������ ��� ���� ������ ���������� ���������
% - ����������� �� ������ ������� �� ���� ��� �����������
% - ����������� �� ����� node-DoF �� ���� ��� �����������
% in, out: K: �� ������ ���������� ��� ���������
% in, out: lcs: �� ������ ������� ��� ���������
% in, out: dofs: �� ����� node-DoF
function [K, lcs, dofs] = compressStiffness(K, lcs, dofs)
	for i = rows(K):-1:1
		if (sum(abs(K(i, :))) < 256 * eps)
			K(i,:) = [];	% �������� ������� (���� �� ������)
			K(:,i) = [];	% �������� ������ (���� � ����������)
			lcs(:,i) = [];	% �������� ������
			dofs(:,i) = [];	% �������� ������ (���� � ������ ����������)
		endif
	endfor
endfunction

% �� ���� �� ����� node-DoF ���� ���������, ���������� ���� ������������ �������
% ��� �� ����� DoFs ���� ���������������� ��� �� ������������ ��������.
% in: dofs: �� ����� node-DoF
function enableDoFsOnNodes(dofs)
	global data;
	for pair = dofs % ���������! �� for ����� ���������� ������ ��� ��� �������
		i = pair(1); % pair: [node index, dof index]
		if (~isfield(data.nodes{i}, "dofs")) data.nodes{i}.dofs = zeros(1, 7); endif
		data.nodes{i}.dofs(pair(2)) = true;
	endfor
endfunction

% ���������� �� ������ ��� ��������� (��������� ��� ������������) �� ���������
% in: dofs: ������� �� 1� ������ ���� ������� ��� ������� ��� 2� ������ �� ����� ����������
% in: loads: �� ��������� ������, ��� �� ������ �� ��� ������ ��� dofs
function convertElementLoadsToNodeLoads(dofs, loads)
	global data;
	for i = 1:columns(dofs)
		dof = dofs(:, i);
		if (~isfield(data.nodes{dof(1)}, 'nodalLoads')) data.nodes{dof(1)}.nodalLoads = zeros(1, 7); endif
		data.nodes{dof(1)}.nodalLoads(dof(2)) += loads(i);
	endfor
endfunction

% ������ ������� ������ ��� ��������� ���������
% ����������� ���� ������� createBarStiffness(), createLinearSpringStiffness()
% in, out: element: �� �������� ��� ������
% in: dofRange: �� ����� ��� ������ ���������� ��� ��������� �� ��������.
% 1:3 ��� ������������ ������� ��� 4:6 ��� ����������.
function element = createLinearSpringCommon(element, dofRange)
	element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
	% Lookup Table: ���� ������ ��� ������� ���������� �� ���� ������ ������-DoF �����������
	% ����������� ���� �� ��������� format, ����� � for ��������� ������(!) ��� ��� �������
	element.dofs(1, 1:3) = element.nodes(1);
	element.dofs(1, 4:6) = element.nodes(2);
	element.dofs(2, 1:3) = element.dofs(2, 4:6) = dofRange;
	% ������� ����� ��� �������� ������� ������ ���������� ��� ��� ����������
	[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
			compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
	% ������ ������� P0 ��� ��������
	if (isfield(element, "initial_load"))
		P = element.initial_load;
		element.loads = [P, -P];
		element.loadGlobal = element.loads * element.lcsMatrix;
	endif
	% ��������� ��� ������ ��� �� ����� ������ ���������� ��������������� ��� �� ��������
	enableDoFsOnNodes(element.dofs);
	if (isfield(element, "loadGlobal"))
		convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
	endif
endfunction

% ���������� ��� �� ����������� �������� ��� ������ �� ������ ��� �������� �������
% ���������� �� L, �� ������ ��� �������� K, �� ������ ��� �������� P0,
% �� ������ ������� ������������� ��� �� ������ �������.
% ��������� ������ ������� ����������, ����� ������, �������� ��� �������� �������
% ��� ���������� ���� ������� ��� ������.
% in, out: element: �� �������� ��� ������
function element = createBarStiffness(element)
	global data;
	% �������� ��������� ��� �� index ����
	material = data.materials{element.material};
	section = data.frame_sections{element.section};
	node1 = data.nodes{element.nodes(1)}.coords;
	node2 = data.nodes{element.nodes(2)}.coords;
	% ����������� ���������� �������������
	element.L = norm(node2 - node1);
	if (~element.L) error(["������ ", element.id, ", ��������� ������"]); endif
	element.direction = (node2 - node1) / element.L;
	element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
	% ����������� ������� ����������
	K = material.E * section.A / element.L;
	element.stiffness = [K, -K; -K, K];
	element = createLinearSpringCommon(element, 1:3);
endfunction

% ���������� ��� �� ����������� �������� ��� ��������� ��������� �� ������ ��� �������� �������
% ���������� �� ������ ��� �������� K, �� ������ ��� �������� P0,
% �� ������ ������� ������������� ��� �� ������ �������.
% ��������� ������ ������� ����������, ����� ������, �������� ��� �������� �������
% ��� ���������� ���� ������� ��� ������.
% in, out: element: �� �������� ��� ���������
function element = createLinearSpringStiffness(element)
	if (length(element.nodes) == 1)
		% ����������� ���������� �������������
		element.lcsMatrix = element.direction;
		% ����������� ������� ����������
		element.stiffness = element.K;
		element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
		% Lookup Table: ���� ������ ��� ������� ���������� �� ���� ������ ������-DoF �����������
		% ����������� ���� �� ��������� format, ����� � for ��������� ������(!) ��� ��� �������
		element.dofs(1, 1:3) = element.nodes(1);
		element.dofs(2, 1:3) = 1:3;
		% ������� ����� ��� �������� ������� ������ ���������� ��� ��� ����������
		[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
				compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
		% ������ ������� P0 ��� ��������
		if (isfield(element, "initial_load"))
			element.loads = element.initial_load;
			element.loadGlobal = element.loads * element.lcsMatrix;
		endif
		% ��������� ��� ������ ��� �� ����� ������ ���������� ��������������� ��� �� ��������
		enableDoFsOnNodes(element.dofs);
		if (isfield(element, "loadGlobal"))
			convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
		endif
	else
		% ����������� ���������� �������������
		element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
		% ����������� ������� ����������
		element.stiffness = [element.K, -element.K; -element.K, element.K];
		element = createLinearSpringCommon(element, 1:3);
	endif
endfunction

% ���������� ��� �� ����������� �������� ��� ��������� ��������� �� ������ ��� �������� �������
% ���������� �� ������ ��� �������� K, �� ������ ��� �������� P0,
% �� ������ ������� ������������� ��� �� ������ �������.
% ��������� ������ ������� ����������, ����� ������, �������� ��� �������� �������
% ��� ���������� ���� ������� ��� ������.
% in, out: element: �� �������� ��� ���������
function element = createTorsionSpringStiffness(element)
	if (length(element.nodes) == 1)
		% ����������� ���������� �������������
		element.lcsMatrix = element.direction;
		% ����������� ������� ����������
		element.stiffness = element.K;
		element.stiffnessGlobal = element.lcsMatrix' * element.stiffness * element.lcsMatrix;
		% Lookup Table: ���� ������ ��� ������� ���������� �� ���� ������ ������-DoF �����������
		% ����������� ���� �� ��������� format, ����� � for ��������� ������(!) ��� ��� �������
		element.dofs(1, 1:3) = element.nodes(1);
		element.dofs(2, 1:3) = 4:6;
		% ������� ����� ��� �������� ������� ������ ���������� ��� ��� ����������
		[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
				compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
		% ������ ������� P0 ��� ��������
		if (isfield(element, "initial_load"))
			element.loads = element.initial_load;
			element.loadGlobal = element.loads * element.lcsMatrix;
		endif
		% ��������� ��� ������ ��� �� ����� ������ ���������� ��������������� ��� �� ��������
		enableDoFsOnNodes(element.dofs);
		if (isfield(element, "loadGlobal"))
			convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
		endif
	else
		% ����������� ���������� �������������
		element.lcsMatrix = [element.direction 0 0 0; 0 0 0 element.direction];
		% ����������� ������� ����������
		element.stiffness = [element.K, -element.K; -element.K, element.K];
		element = createLinearSpringCommon(element, 4:6);
	endif

endfunction

% ���������� ��� �� ����������� �������� ��� ����� �� ������ ��� �������� �������
% ���������� �� L, �� ������ ��� �������� K, �� ������ ��� �������� P0,
% �� ������ ������� ������������� ��� �� ������ �������.
% ��������� ������ ������� ����������, ����� ������, �������� ��� �������� �������
% ��� ���������� ���� ������� ��� ������.
% in, out: element: �� �������� ��� ������
function element = createBeamStiffness(element)
	global data;
	% �������� ��������� ��� �� index ����
	material = data.materials{element.material};
	section = data.frame_sections{element.section};
	node1 = data.nodes{element.nodes(1)}.coords;
	node2 = data.nodes{element.nodes(2)}.coords;
	% ����������� ���������� �������������
	L = element.L = norm(node2 - node1);
	if (~element.L) error(["����� ", element.id, ", ��������� ������"]); endif
	axisX = (node2 - node1) / element.L;
	if (isfield(element, "axisZ"))	% ����� ���������
		axisZ = element.axisZ;
		element = rmfield(element, "axisZ");
		axisY = cross(axisZ, axisX);
		n = norm(axisY);
		if (n < 0.02)
			error(["��� ���� ", element.id, ", � ������ z ������ �� ���� ����� ����������� 1.145� �� ��� ����� x, ���� ", ...
					num2str(asin(n * 180 / pi)), "�"]);
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
	% ���������, ������� ��� ������������
	element.lcsMatrix(14, 14) = element.lcsMatrix(7, 7) = 1;
	element.lcsMatrix(1:3, 1:3) = element.lcsMatrix(4:6, 4:6) = ...
	element.lcsMatrix(8:10, 8:10) = element.lcsMatrix(11:13, 11:13) = element.lcs;
	%
	% ����������� ��������� ������������� �������
	if (isfield(element, 'distributed_loads'))
		P = zeros(2, 6);
		for i = element.distributed_loads
			load = data.loads{i};
			% �� ����� ��� �������� �������, ������ ��� ������
			if (~load.lcs) load.coords *= element.lcs'; endif
			% �������� ��� ����� ������������� ��������� (� ��� ����������� ��������� ��� �������������)
			if (~isfield(load, "magnitude")) load.coords .*= [1;1];
			else load.coords .*= load.magnitude';	% �� 2 ��������. �� ���� �� 1, �� ���� ����������� ��� .coords
			endif
			a = load.coords(1,1); b = load.coords(2,1);
			if (load.force) P(:, 1:3) += load.coords;
			else P(:, 4:6) += load.coords;
			endif
		endfor
		element.distributed_loads = P;
	endif
	%
	% ����������� ������� ����������
	%
	% ����������� �������� ����������/������
	E = material.E;
	if (isfield(section, "A"))
		A = section.A;
		K11 = E * A / L;
	else
		warning(["����� ", element.id, ", �� ������� ", section.id, ...
				", ����� A: ����� ��� ��� ������������ ������� ������"]);
		A = 0;
		K11 = 0;
	endif
	%
	% ����������� �������� ������-���������
	% ����� ���� ����� z
	if (isfield(section, "Iz"))
		Iz = section.Iz;
		if (isfield(material, "G") && A && isfield(section, "ay"))
			G = material.G; ay = section.ay;
			% ����������� �������� ������-��������� Timoshenko
			c5 = A * G * Iz * E; c2 = A * G * L^2; c6 = ay * Iz * E; c7 = c2 + 12 * c6;
			K22 = 12 * c5 / c7 / L;
			K62 = 6 * c5 / c7;
			K66 = 4 * Iz * E * (c2 + 3 * c6) / c7 / L;
			KD6 = 2 * Iz * E * (c2 - 6 * c6) / c7 / L;
		else
			warning(["����� ", element.id, ", �� ����� ", material.id, " ����� v � ������� ", ...
					section.id, " ����� A ��� ay: �� �������������� ����� Euler, ���� ����� z"]);
			% ����������� �������� ������ Euler
			c = E * Iz / L;
			K22 = 12 * c / L^2;
			K62 =  6 * c / L;
			K66 =  4 * c;
			KD6 =  2 * c;
		endif
	else
		warning(["����� ", element.id, ", �� ������� ", section.id, ...
				", ����� Iz: ����� ��� ��� ������������ �� ����� ���� ����� z"]);
		K22 = K62 = K66 = KD6 = 0;
	endif
	% ����� ���� ����� y
	if (isfield(section, "Iy"))
		Iy = section.Iy;
		if (isfield(material, "G") && A && isfield(section, "az"))
			G = material.G; az = section.az;
			% ����������� �������� ������-��������� Timoshenko
			c1 = A * G * Iy * E; c2 = A * G * L^2; c3 = az * Iy * E; c4 = c2 + 12 * c3;
			K33 = 12 * c1 / c4 / L;
			K53 = -6 * c1 / c4;
			K55 = 4 * Iy * E * (c2 + 3 * c3) / c4 / L;
			KC5 = 2 * Iy * E * (c2 - 6 * c3) / c4 / L;
		else
			warning(["����� ", element.id, ", �� ����� ", material.id, " ����� v � ������� ", ...
					section.id, " ����� A ��� az: �� �������������� ����� Euler, ���� ����� y"]);
			% ����������� �������� ������ Euler
			c = E * Iy / L;
			K33 = 12 * c / L^2;
			K53 = -6 * c / L;
			K55 =  4 * c;
			KC5 =  2 * c;
		endif
	else
		warning(["����� ", element.id, ", �� ������� ", section.id, ...
				", ����� Iz: ����� ��� ��� ������������ �� ����� ���� ����� z"]);
		K33 = K53 = K55 = KC5 = 0;
	endif
	%
	% ����������� �������� �������-����������
	if (isfield(material, "G") && isfield(section, "It"))
		G = material.G;
		if (all(isfield(section, {"It_S", "Cs"})))
			ItP = section.It; ItS = section.It_S; Cs = section.Cs;
			% ����������� �������� ������������� �������-���������� �� STMDE
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
			% ����������� �������� ������������� �������-����������
			t1 = sqrt(E * Cs); t2 = sqrt(G * It); t3 = t2 / t1; t4 = t3 * L / 2;
			t5 = e^(2 * t4); t6 = t2 * L * (t5^2 - 1) - 2 * t1 * (t5 - 1)^2;
			K44 = t2^2 / (L * (1 - tanh(t4) / t4));
		else
			It = section.It;
			% ����������� �������� ������ Saint Venant
			K44 = G * It / L;
			K74 = K77 = KE7 = 0;
			if (element.warp)	% �� � ����� ����������� ���������
				warning(["����� ", element.id, ", ����������� ���������, ���� ������� ��� ", section.id, ...
				", ����� Iz: ����� ��� ��� ������������ �� ����� ���� ����� z"]);
			endif
		endif
		% �� � ����� ��� ����������� ��������� ������� ���������� ���
		if (~element.warp)
			if (K77 + KE7) K44 -= 2 * K74^2 / (K77 + KE7); endif
			K74 = K77 = KE7 = 0;
		endif
	else
		warning(["����� ", element.id, ", �� ����� ", material.id, " ����� v � ������� ", ...
					section.id, " ����� It: ����� ��� ��� ������������ �� ������"]);
		K44 = K74 = K77 = KE7 = 0;
	endif
	%
	% �� ������
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
	% Lookup Table: ���� ������ ��� ������� ���������� �� ���� ������ ������-DoF �����������
	% ����������� ���� �� ��������� format, ����� � for ��������� ������(!) ��� ��� �������
	element.dofs(1, 1:7) = element.nodes(1);
	element.dofs(1, 8:14) = element.nodes(2);
	element.dofs(2, 1:3) = element.dofs(2, 8:10) = 1:3;		% ��������������
	element.dofs(2, 4:6) = element.dofs(2, 11:13) = 4:6;	% ���������
	element.dofs(2, 7) = element.dofs(2, 14) = 7;					% ���������
	% ������� ����� ��� �������� ������� ������ ���������� ��� ��� ����������
	[element.stiffnessGlobal, element.lcsMatrix, element.dofs] = ...
			compressStiffness(element.stiffnessGlobal, element.lcsMatrix, element.dofs);
	%
	% ������������ ������
	if (isfield(element, "distributed_loads"))
		P = zeros(1, 14);
		% ������� ��������� ��������� �����
		a = element.distributed_loads(1,1); b = element.distributed_loads(2,1);
		if (a || b)
			P(1) -= -L * (2 * a + b) / 6;
			P(8) -= -L * (a + 2 * b) / 6;
		endif
		% �������� ���� ����� y ��������� ��������� ����� (����� ���� ����� z)
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
		% �������� ���� ����� z ��������� ��������� ����� (����� ���� ����� y)
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
		% ���� ���� ����� x ��������� ��������� ����� (������)
		a = element.distributed_loads(1,4); b = element.distributed_loads(2,4);
		if (a || b)
			if (exist("ItP"))		% ������������ ������ �� STMDE
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
			elseif(exist("Cs"))	% ������������ ������
				p1 = (a - b) / (t3^2 * L);
				p2 = (a + b) * L / 4;
				p3 = t4 * (a - b) * L / (12(t4 - tanh(t4)));
				P(4) -= p1 - p2 - p3;
				P(7) -= a / t3^2 - (a + b) * L * coth(t4) / (4 * t3) ...
								- (a - b) * L^2 / (24 * (t4 * coth(t4) - 1));
				P(11) -= -p1 - p3 + p3;
				P(14) -= (6 * b + 2 * (a + 2 * b) * t4^2 + 3 * t4 * ((a + b) * t4 * csch(t4)^2 - (a + 3 * b) * coth(t4))) ...
						/ (6 * t3^2 *(t4 * coth(t4) - 1));
			else								% ���������� ������ Saint Venant
				P(4) -= -(2 * a + b) * L / 6;
				P(11) -= -(a + 2 * b) * L / 6;
			endif
		endif
		% ���� ���� ����� y ��������� ��������� ����� (����� ���� ����� y)
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
		% ���� ���� ����� z ��������� ��������� ����� (����� ���� ����� z)
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
	% ���������� ������� ���� ������������� �������
	if (isfield(element, "initial_load"))
		P = element.initial_load;
		P = [P, -P];
		if (isfield(element, "loads")) element.loads += P; else element.loads = P; endif
	endif
	% ������ ������� P0 ��� ��������
	if (isfield(element, "loads"))
		element.loadGlobal = element.loads * element.lcsMatrix;
		% ������� ����� ������� ������ ��������� ������� ���� ��������� ������������ ����������
		if (norm(element.loadGlobal * element.lcsMatrix' - element.loads) > 256 * eps)
			error(["� ����� ", element.id, ", ���� ��������� �������� �� ����� ���������� ��� ��� ����������� ���������"]);
		endif
	endif
	% ��������� ��� ������ ��� �� ����� ������ ���������� ��������������� ��� �� ��������
	enableDoFsOnNodes(element.dofs);
	if (isfield(element, "loadGlobal"))
		convertElementLoadsToNodeLoads(element.dofs, element.loadGlobal);
	endif
endfunction


% ���������� ��� �� ����������� ��������, ���� ��� ��������� ��� �����.
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
			%TODO: ����� ��������
		endswitch
	endfor
endfunction

% ��������� ���� ��� ������������� �� ������������� ��� ����� � ��� ����������� �����
% ��� ������� ����: �� ������ �.�. ux = 0.001 ���� � ������������� ����� ����� �� 1
% ��� � �������� ���� �� 0.01.
% ������������� ���� ������������ ��� ���� ���������� ����� ���������� ���� ������.
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
				data.constraints{++pos} = constraint;		% �������� ������������ ��� ����� ������������
			endfor
		endfor
	endfor
endfunction

% ���������� ��� ��������� ��� �������� ��� ������������, ���� ���������� ������
% in: con: � ������������
% out: eq: �� ��������� ��� �������� ��� ������������
function eq = makeRigidConstraint(con)
	global data;
	c = [0 0 0];						% ������ ������ ��� ����������� ������ ����������
	n = [0 0 0  0 0 0  0];	% ������� ������ ���������� �� ���� ��������/���������� �����
	f = [0 0 0];						% Index ��� 1�� ��������� ������ ���������� ��� ����� ��� DoFs
	cols = columns(con.dofs);
	for i = 1:cols
		dof = con.dofs(:, i);
		++n(dof(2));
		if (dof(2) <= 3) c(dof(2)) += data.nodes{dof(1)}.coords(dof(2));
		elseif (dof(2) <= 6 && ~f(dof(2) - 3)) f(dof(2) - 3) = i;
		endif
	endfor
	c ./= n(1:3);	% ��� sum �� average
	% ������� ��� ��������� ��������
	if (n(1) == 1 || n(2) == 1 || n(3) == 1 || n(7) == 1 || ...
			n(4) == 1 && n(2) < 2 && n(3) < 2 || ...
			n(5) == 1 && n(1) < 2 && n(3) < 2 || ...
			n(6) == 1 && n(1) < 2 && n(2) < 2)
		error(["���� ����������� ������� ", con.id, " �������� ����������� ������ ����������"]);
	endif
	% � ������� ������� ��� ��� ���� ����� ���������� ������ �� �������� ����� ��� ����� �������� ����������
	skip = [true, true, true,  true, true, true,  true];
	eq = [];	% ��������� Lagrange
	ii = 0; % �������� �������
	for i = 1:cols
		dof = con.dofs(:, i);
		% � ����� ����� �� ���� ����� �������� � ���������� ��������� ������ ��� ����� �������� ����������
		% � ������� ��� ������ ����� ������. ����������� ����� �� �������� �� �����.
		if (skip(dof(2))) skip(dof(2)) = false;
		else
			++ii;
			% ���������� �������� ����� ������������� �������-�����������
			for j = 1:cols
				if (i == j) eq(ii, j) = 1 / n(dof(2)) - 1;		% ����� ���������
				elseif (dof(2) == con.dofs(2, j)) eq(ii, j) = 1 / n(dof(2));	% ������ ���������� ���� ���� �����
				endif
			endfor
			% �������� �������������� �������-����������� ��� �������������� �������
			switch(dof(2))
				case 1	% �������������� ������ ���������� x
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

% ���������� ��� ����������� �������������� ������������ ������� ���� ������������� ��������
% in: A: �� ������� ��� ������ ��������� �� ������������ �������
% out: X: �� ������� ��� ������ ��������� �� �������������� ������� ��� �������� �.
% ���������� nan �� � �������� � ����� �������������
function X = findComplementVectorSubspace(A)
	A = rref(A);
	swaps = [];		% ������� ��� ������� ������ ����������� � � �� ����� ��������� ����������
	r = rows(A);
	if (~any(A(r, :))) X = nan; return; endif
	ii = 1;
	% ������������ ������ ���� � � �� ����� A = [I B]
	for i = 1:r
		while(~A(i, ii)) ii++; endwhile
		if (i ~= ii)
			swaps = [swaps, [i; ii]];
			x = A(:, i); A(:, i) = A(:, ii); A(:, ii) = x;
		endif
	endfor
	% ����������� ��� ��������������� ������������� ��������
	A = -A(:, r+1:columns(A))';
	r2 = rows(A);
	X = [A, eye(r2)];
	% ������������ ������ ���� � � �� ����� ���� ������
	for i = swaps
		x = X(:, i(1)); X(:, i(1)) = X(:, i(2)); X(:, i(2)) = x;
	endfor
endfunction

% ����������� ���� ������������� ������ ������ ����������
% �� ������������ ������ ������������� �� ��������� ��� �������� ��� ������������.
% ���� ���� ��� ����� ������. �� ������ �� ���������� ������� ��������� (��� ���
% ���� �������� � ���������� �����) ��� �� �������� ��� ����������� (�����/��������).
% ����� ���� ������������� ����� ��������� Lagrange ��������������, �� ������ ��
% ���������� � solver.
function linkConstrainedDoFs()
	global data;
	for cidx = 1:length(data.constraints)
		c = data.constraints{cidx};	% ����������
		% �� ��� ����� ����������� �� ��������� ��� ������������ ������ �� ������������ ����
		if (~isfield(c, "disp_eq"))
			c.disp_eq = makeRigidConstraint(c);
			c.disp_const = zeros(1, rows(c.disp_eq));
		endif
		% ������ ��� ������������� ����� ��� ��������� ��� ������������
		if (isfield(c, "lcs"))
			% � ������� ������� ��� DoFs ��� ������ ��� �������� �� ������ �������
			% �� �� DoFs ������� ���� ��� ���� �� ��� �������� �����
			% � ������� �� ������� ����������
			R = zeros(7); R(4:6, 4:6) = R(1:3, 1:3) = c.lcs'; R(7, 7) = 1;
			% �� ������ ���������� ��� �������� �������
			dofs = [];
			% � ������� ������� ��� DoFs ���� ��� ������ ��� ���������
			Rr = [];
			i = 1;
			e = columns(c.dofs);
			while (i)
				% � ���������������� ������� ������� ��� DoFs ��� ������ ��� �������� ��
				% ������ �������, ���� ��� ����� DoFs ��������
				RR = [];
				node = c.dofs(1, i);
				% �� ����� ��� DoFs ��� ������ ��� �������� �������
				% �� ������� ������ ��� RR ����� ��������� �� ����������, ��� ���� ��
				% ����������� ������ ��� u
				u = [node, node, node, node, node, node, node; 1 2 3 4 5 6 7];
				% ���������� ��� ������� ��� R
				for j = i:i+7
					if (j > e) ii = 0; break; endif % ��������� �� DoFs ��� ���������
					if (node ~= c.dofs(1, j)) ii = j; break; endif % ��� �������� � �������� ������
					RR = [RR; R(c.dofs(2, j), :)];
				endfor
				for j = columns(RR):-1:1
					if (~any(RR(:, j))) RR(:,j) = []; u(:,j) = []; endif
				endfor
				dofs = [dofs; u];			% �� DoFs ��� ������ ��� ����� �� ����� ���� DoFs
				% �� ������ ������� ��� DoFs ��� ������ ��� ������ ������� ���� ��� ���������
				rf = rows(Rr); rt = rf + rows(RR);
				cf = columns(Rr); ct = cf + columns(RR);
				Rr(rf+1:rt, cf+1:ct) = RR;
				i = ii;
			endwhile
			% ��� �� ������ ��������������� ��� �� ��������
			c.disp_eq = c.disp_eq * Rr;
			c.dofs = dofs;
		endif
		% ������� �� �� ������ ���������� ��� ����������� ��������
		% �� ��� �������� ����� ������
		% �� �������� ����������� ��� �� ������ ���� ������� ���������� �� ����������� �����������
		for i = c.dofs
			if (~data.nodes{i(1)}.dofs(i(2)))
				error(["� �������� ", c.id, " ���������� ��� ����� ���������� ", ...
						num2str(i(2)), " ��� ������ ", data.nodes{i(1)}.id, ' ��� ��� �������']);
			else
				% ���������� �� 0 ���� ����� ��� �� ���������� ������ ���������� (������ ����� nan)
				if (~isfield(data.nodes{i(1)}, "reactions")) data.nodes{i(1)}.reactions = nan(1, 7); endif
				data.nodes{i(1)}.reactions(i(2)) = 0;
			endif
		endfor
		% ������� �� �� ��������� ��� �������� ����� ���� �� ���� ������� ����������
		% ��� ��������� ������������ (�������)
		if (rows(c.disp_eq) == columns(c.dofs))
			% ������� �� ������������� � �������
			if (rcond(c.disp_eq) < 256 * eps)
				error(["�� ������� ��� ������������ ��� ������������ ", c.id, ...
						", ��� ����� ����� ����������. ������� ���� ������������, ���� �����������������."]);
			endif
			u = c.disp_const / c.disp_eq';		% ������� ��� ���������� ��� �� ������� �� ������������
			for i = 1:columns(c.dofs)
				dof = c.dofs(:, i);
				if (~isfield(data.nodes{dof(1)}, "displacements"))
					data.nodes{dof(1)}.displacements = nan(1, 7);
				endif
				data.nodes{dof(1)}.dofs(dof(2)) = -1;	% ���������� � DoF �����������
				data.nodes{dof(1)}.displacements(dof(2)) = u(i); % ����������� �� ����
			endfor
		else
			% ����������� ��� ��������� ��� ����������� �������� ��� ������������
			c.react_eq = findComplementVectorSubspace(c.disp_eq);
			if (isnan(c.react_eq))
				error(["�� ������� ��� ������������ ��� ������������ ", c.id, ...
						", ��� ����� ����� ����������. ������� ���� ������������, ���� �����������������."]);
			endif
			% ��������� ��� solver ��� �� ����� ��������� Lagrange �� ���������� �������� ��� ������������
			data.solver.totalLagrangeEquations += rows(c.disp_eq) + rows(c.react_eq);
			data.constraints{cidx} = c;
		endif
	endfor
endfunction

% ���������� ���� lookup table �� ���� node ��� ������������ ���� ������� ����������
% ��� �� ������ ����������� ��� ������� ���������� ��� �����.
% �� � ���� ����� 0 �������� ��� � ������ ���������� ��� ����� �������.
% �� ����� ������ �������� ��� � ������ ���������� ����� ��������� ��� ������� ��
% ����������� ���� ���������� ������ ��� �����.
% �� ����� �������� �������� ��� � ������ ���������� ����� ����������� ��� ������� ��
% ����������� ���� ���������� ������ ��� �����.
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
	% ��������� ��� solver ������ ��������� ��� ����������� ������ ����������
	data.solver.free = free;
	data.solver.freeAll = free + data.solver.totalLagrangeEquations;
	data.solver.fixed = -fixed;
	data.solver.nextLagrangeEquation = free + 1;	% Index ��� ������ ����� ��� ���������� Lagrange ��������
endfunction

% ������������ ������� ���������� ��� ����������� ��� �����
function initStructureStiffness()
	global data;
	% ���������� ������ ������� ��� ��� ���������� ����. �������� �� ������ ������.
	data.solver.stiffness1 = zeros(data.solver.freeAll);
	data.solver.stiffness2 = zeros(data.solver.fixed);
	data.solver.stiffness12 = zeros(data.solver.freeAll, data.solver.fixed);
	data.solver.loads1 = zeros(1, data.solver.freeAll);
	data.solver.loads2 = data.solver.displacements2 = zeros(1, data.solver.fixed);
endfunction

% ����������� �� ������ ��� ���������� ��� �����, �� ����� ��� �� ����
function populateStructureStiffnessFromElements()
	global data;
	% ��������� ��� ��� �� ���� ��� �����
	for element = data.elements
		element = element{1};
		% �� ������ ���������� ��� ������ ��� ������ ���������� ��� �����
		for i = 1:rows(element.stiffnessGlobal)
			for j = 1:columns(element.stiffnessGlobal)
				el = element.stiffnessGlobal(i, j);
				row = data.nodes{element.dofs(1, i)}.dofs(element.dofs(2, i));
				col = data.nodes{element.dofs(1, j)}.dofs(element.dofs(2, j));
				if (row > 0 && col > 0) data.solver.stiffness1(row, col) += el;
				elseif (row < 0 && col < 0) data.solver.stiffness2(-row, -col) += el;
				elseif (row > 0 && col < 0) data.solver.stiffness12(row, -col) += el;
				%else � ������� stiffness21 �� ����������
				endif
			endfor
		endfor
		% �� �������� ������� ������� ��� ������ ��� �������� ������� ��� �����
		% �� ���������� ����� ����� �������� �� ������ ����� ������� ��� �� ����� ��� ����
	endfor
endfunction

% ��������� ��� ������� Lagrange, ��� ������� ������������, ��� ������ K.
% in: row: � ������ ��� ������ K, ���� ����� �� ��������� � �������.
% in: coefs: �� ����������� ��� ������ ���������� ��� �� ������������ ��� �.
% in: dofs: ������� �� 1� ������ �� index ��� ������ ��� 2� ������ �� index ��� DoFs
% in: const: � �������� ���� ��� �������� Lagrange ��� ������������ ��� ��������
% ��� �������.
% � ������� Lagrange ����� coefs * dofs = const.
function addDisplacementLagrangeEquation(row, coefs, dofs, const)
	global data;
	% ��� ���������� "+=" ���� ����� "=" ����� ���� ��� ����� �� ��������� Lagrance
	% �� ������ ������ ���� ��������.
	% �������� ���� �������� � Lagrange - ������������ ��� �������� ��� ���������
	data.solver.loads1(row) = const;
	% �� ���� ����� ������� stiffness1 ��� stiffness12
	% ������������� ���� �� �������. �� ������ �� ������������ �� ���������
	% ��� ��������� ��� ������� (��������� ��� �� ������� ������ ���� ���
	% �������� ����� ��������)
	for i = 1:columns(coefs)
		if (~coefs(i)) continue; endif
		col = data.nodes{dofs(1, i)}.dofs(dof = dofs(2, i));
		if (col > 0) data.solver.stiffness1(row, col) = coefs(i);
		else data.solver.stiffness12(row, -col) = coefs(i);
		endif
	endfor
endfunction

% ��������� ��� ������� Lagrange, ��� ������� �����������, ��� ������ K.
% in: row: � ������ ��� ������ K, ���� ����� �� ��������� � �������.
% in: coefs: �� ����������� ��� ����������� ��� �� ������������ ��� �.
% in: dofs: ������� �� 1� ������ �� index ��� ������ ��� 2� ������ �� index ��� DoFs
% � ������� Lagrange ����� K * coefs * dofs = K * P.
function addReactionLagrangeEquation(row, coefs, dofs)
	global data;
	% �� ���� ����� ������� stiffness1 ��� stiffness12
	% ������������� ���� �� �������. �� ������ �� ������������ �� ���������
	% ��� ��������� ��� ������� (��������� ��� �� ������� ������ ���� ���
	% �������� ����� ��������)
	data.solver.stiffness1(row, :) = 0;  % ������������ ����� ���� ���� "+="
	data.solver.stiffness12(row, :) = 0; % ������������ ����� ���� ���� "+="
	data.solver.loads1(row) = 0;         % ������������ ����� ���� ���� "+="
	for i = 1:columns(coefs)
		if (~coefs(i)) continue; endif
		rowSrc = data.nodes{dofs(1, i)}.dofs(dofs(2, i));
		data.solver.stiffness1(row, :) += coefs(i) * data.solver.stiffness1(rowSrc, :);
		data.solver.stiffness12(row, :) += coefs(i) * data.solver.stiffness12(rowSrc, :);
		data.solver.loads1(row) += coefs(i) * data.solver.loads1(rowSrc);
	endfor

endfunction

% ����������� �� ������ ��� �����, �� ����� ��� ��� ��������� ��������������� Lagrange
% ��� ������������ (constraints)
function populateStructureStiffnessFromConstraints()
	global data;
	% ��������� ���� ���� ����� ���� ������������� ��� �����
	for con = data.constraints
		con = con{1};
		if (isfield(con, "react_eq"))	% ��� ������ �������� ������ ���������� ��� ���� ������� Lagrange
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

% ����������� �� ��������� ���������� ��� ����� �� ��������� ������ ��� ����������
% ���������� ������������ ��� ������������� (restraints)
function populateStructureStiffnessFromNodes()
	global data;
	% ��������� ���� ���� ����� ���� �������
	for nodeidx = 1:length(data.nodes)
		node = data.nodes{nodeidx};
		% �� ����� ��� ����������� ������ ���������� ��� ������ ������������� ���
		% �������� ��� ���������� ������������
		for i = 1:7
			dofidx = node.dofs(i);
			if (dofidx < 0)
				data.solver.displacements2(-dofidx) = node.displacements(i);
			endif
		endfor
		% ���������� ��� ���������� ������� ��� ������, �� ��������
		if (isfield(node, 'nodalLoads'))
			% ������������ ������ ��� ����������� ����. ���� �� �����, ���� ������.
			data.nodes{nodeidx}.actions = node.nodalLoads;
			for i = 1:7
				el = node.nodalLoads(i);
				if (el)
					dofidx = node.dofs(i);
					if (dofidx > 0)     data.solver.loads1(dofidx) += el;
					elseif (dofidx < 0) data.solver.loads2(-dofidx) += el;
					else	% �� ��������� ��� ������� ������� �� ����� ���������� ��� ��� ����������� � ������
						error(["O ������ ", node.id, " ��� ���� �� ����� ���������� ", ...
								num2str(start + i), " ���� ����� ������� ��������� �������"]);
					endif
				endif
			endfor
		endif
	endfor
endfunction


% ======================================================================= SOLVER


% ������� ��� �����.
% ���������� ��� ��� ��� �������� Conjugate Gradient (����� ���������������
% Lagrange) � Conjugate Residuals (�� ��������������� Lagrange)
% �� ��� ��������� (������ �������) ����������� ������� ������ �������.
function solveStructure()
	global data;
	% �� ���� ��� ��������� Lagrange ���������� ��� ������ ���� �� �������.
	% ��� �� ��������� ��� ��� ������.
	data.solver.stiffness1(1:data.solver.free, data.solver.free + 1 : data.solver.freeAll) = ...
			data.solver.stiffness1(data.solver.free + 1 : data.solver.freeAll, 1:data.solver.free)';
	% ����� 50 ������� ���������� ������� �� ��� ������� ������ ������ �������
	if (length(data.solver.stiffness1) > 50)
		% ���������� ������ ������ ��� ��� �����
		data.solver.stiffness1 = sparse(data.solver.stiffness1);
		data.solver.stiffness12 = sparse(data.solver.stiffness12);
		data.solver.stiffness2 = sparse(data.solver.stiffness2);
	endif

	% �������
	%
	% �� ������ ���������� ����� ����������� ������ ��������� �������, ����� � ������
	% ��������� ���� ��� ������ �������������� ���������, ��� ?E=�F=0 ��� ?(?E)=?�F=[K]
	% ��� �������� ��� � [K] ����� ������ ���������.
	% � �������� ������� ��� ������� ����������� ������ ��������� ������� ����� �
	% Conjugate Gradient.
	% ���� ���� ����������� ������� � ��������������� Lagrange ��� ������ [K], ����
	% ��������� ���������� ���� ����� �� ����� ������ ��������. ��� ��� ������ ��
	% �������������� � Conjugate Gradient.
	A = data.solver.stiffness1;
	b = data.solver.loads1' - data.solver.stiffness12 * data.solver.displacements2';
	% ����� 50 ������� ���������� ������� �� ��� ������� ������ ������ �������
	if (length(b) > 50)
		if (~data.solver.totalLagrangeEquations)
			[data.solver.displacements1, flag, tol, it] = pcg(A, b, 10^-10, 1500);
			switch(flag)
				case 0 data.solver.method = ['Conjugent Gradient: iterations=', num2str(it), ', norm(b-A*x)=', num2str(tol)];
				case 1 warning("Conjugate Gradient: � ������� �������� ��� ������������� ����������� ����� �� ��������������� �� ������ ���� ��� �� �����������");
				case 2 error("Conjugate Gradient: ������ ������ ��� ������� ��� ����� - �� ������ ���������� �11 ��� �������������");
				case 3 warning("Conjugate Gradient: '�������' �� ���� ��� ��� ����� � ����");
				% ������ �� �� �������� ���� � ��������� ����:
				case 4 warning("Conjugate Gradient: ������� �� ������ ��������� �������");
			endswitch
		endif
		% � �������� ������� (��� ���� ��� ��� Conjugate Gradient) ��� ������������
		% ������� ����� � Conjugate Residuals.
		if (data.solver.totalLagrangeEquations || flag)
			[data.solver.displacements1, flag, tol, it] = pcr(A, b, 10^-15, 1500);
			switch(flag)
				case 0 data.solver.method = ['Conjugent Residuals: iterations=', num2str(it), ', norm(b-A*x)=', num2str(tol)];
				case 1 warning("Conjugate Residuals: � ������� �������� ��� ������������� ����������� ����� �� ��������������� �� ������ ���� ��� �� �����������");
				case 2 error("Conjugate Residuals: ������ ������ ��� ������� ��� ����� - �� ������ ���������� �11 ��� �������������");
				case 3 warning("Conjugate Residuals: Breakdown");
			endswitch
		endif
	endif
	% � ��������� ������� ����� � ������� ��� ������ �������
	if (length(b) <= 50 || flag)
		data.solver.method = 'Dense matrix \';
		if (rcond(A) < 65535 * eps) error("���� ���� ������ ���������� ����� ��� ���� ��� �������������"); endif
		data.solver.displacements1 = A \ b;
	endif
	
	% ������ ��� ��������� ��� ������� ��� ��������������� Lagrange
	data.solver.stiffness1 = data.solver.stiffness1(1:data.solver.free, 1:data.solver.free);
	data.solver.stiffness12 = data.solver.stiffness12(1:data.solver.free, :);
	data.solver.displacements1 = data.solver.displacements1'(1:data.solver.free); % ���������!
	data.solver.loads1 = data.solver.loads1(1:data.solver.free);
	% ������������ ��� ����������� ��� ��������� ������ ����������.
	% ���� ����� ������� ��� ���� "����������" ������� ���������� ����� �����������
	% �� ��������� ����������� ��� ��� ���������.
	data.solver.reactions1 = data.solver.displacements1 * data.solver.stiffness1 + ...
			data.solver.displacements2 * data.solver.stiffness12' - data.solver.loads1;
	% ������������ ��� ����������� ��� ����������� ������ ����������.
	data.solver.reactions2 = data.solver.displacements1 * data.solver.stiffness12 + ...
			data.solver.displacements2 * data.solver.stiffness2 - data.solver.loads2;
endfunction


% ============================================================== POST-PROCESSING


% �� ������������ ����������� - ������������ ������������� �� ���� �����
function outputToNodes()
	global data;
	for nodeidx = 1:length(data.nodes)
		% �� �������� �����������, �� ��������� ��� � ������� �������-�����������
		if (isfield(data.nodes{nodeidx}, 'reactions') && ~isfield(data.nodes{nodeidx}, 'actions'))
			data.nodes{nodeidx}.actions = zeros(1, 7);
		endif
		for dofidx = 1:7
			row = data.nodes{nodeidx}.dofs(dofidx);	% ����� ��� P ��� �, ��� ��������� ������ ��� ����������
			react = isfield(data.nodes{nodeidx}, 'reactions') && ~isnan(data.nodes{nodeidx}.reactions(dofidx));	% ������� ���������
			if (row > 0)
				data.nodes{nodeidx}.displacements(dofidx) = data.solver.displacements1(row);
				if (react)
					data.nodes{nodeidx}.reactions(dofidx) = data.solver.reactions1(row);
					data.nodes{nodeidx}.actions(dofidx)  += data.solver.reactions1(row);
				endif
			elseif (row < 0 && react)
				% �� ������������ �������� ���
				data.nodes{nodeidx}.reactions(dofidx) = data.solver.reactions2(-row);
				data.nodes{nodeidx}.actions(dofidx)  += data.solver.reactions2(-row);
			endif
		endfor
	endfor
endfunction

% �� ������������ ����������� - ������������ ������������� �� ���� ��������-�����
function outputToElements()
	global data;
	for elementidx = 1:length(data.elements)
		element = data.elements{elementidx};
		% ��������� ��� ������������ ��� ������ ���������� ��� ������ ��� ���������� �� ��������
		displacements = zeros(1, columns(element.dofs));
		for dofidx = 1:length(displacements)
			dof = element.dofs(:, dofidx);
			row = data.nodes{dof(1)}.dofs(dof(2));
			if (row > 0) displacements(dofidx) = data.solver.displacements1(row);
			else displacements(dofidx) = data.solver.displacements2(-row);
			endif
		endfor
		% �� ������������ �� ������ ������� ��� ��������, ����� ��� �� �����������
		% ��� ��������� ��� ���������
		data.elements{elementidx}.displacements = displacements = displacements * element.lcsMatrix';
		loads = displacements * element.stiffness;
		if (isfield(element, "loads")) loads -= element.loads; endif
		data.elements{elementidx}.reactions = loads;
	endfor
endfunction

% ������ ��� ���������/�����, ��� ������� ��� ��� ���� ���� ������
function outputBarFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'�x', 'N', '�<sub>x</sub>', '�<sub>VonMises</sub>'};
	dx = element.displacements(2) - element.displacements(1);	% �x
	N = -element.reactions(1);								% �������
	sx = N / data.frame_sections{element.section}.A;	% ����
	element.function_values = [dx, N, sx, sx];
	data.elements{index} = element;
endfunction

% ������ ������������, ������ ��� �������� ������ ���� �����.
% ��� ������ ������ ������ ��� ��� ������������.
function outputBeamFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'L-th', 'x', 'u<sub>x</sub>', 'u<sub>y</sub>', 'u<sub>z</sub>', ...
			'�<sub>x</sub>', '�<sub>y</sub>', '�<sub>z</sub>', 'N', 'V<sub>y</sub>', ...
			'V<sub>z</sub>', 'M<sub>x</sub>', 'M<sub>y</sub>', 'M<sub>z</sub>', 'M<sub>w</sub>', ...
			'�<sub>xx,max</sub>', '�<sub>xy,max</sub>', '�<sub>xz,max</sub>', '�<sub>yy,max</sub>', ...
			'�<sub>yz,max</sub>', '�<sub>zz,max</sub>', '�<sub>VonMises</sub>'};
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

% ������ �� ���������� ��� �� ������ ���� ��������� ���������
function outputLinearSpringFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'�x', 'F'};
	if (length(element.nodes) == 1) dx = element.displacements(1);
	else dx = element.displacements(2) - element.displacements(1);	% �x
	endif
	F = -element.reactions(1);
	element.function_values = [dx, F];
	data.elements{index} = element;
endfunction

% ������ �� ������ ��� �� ���� ���� ��������� ���������
function outputTorsionSpringFunctions(index)
	global data;
	element = data.elements{index};
	element.functions = {'��', 'M'};
	if (length(element.nodes) == 1) dx = element.displacements(1);
	else dx = element.displacements(2) - element.displacements(1);	% �x
	endif
	M = -element.reactions(1);
	element.function_values = [dx, M];
	data.elements{index} = element;
endfunction

% ������ ��� ����������� ��� ��������� �.�. N(x), Vy(x), u(x) ���
% ��� ���� �������� ����� ������������
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

% ============================================================= ������� ��������

% �������� ��� index ���� DoF ���������� �� ����� ���.
% in: i: �� index ��� DoF ��� 1 ����� 7
% out: i: �� ����� ��� DoF ��� 'disp_x' ����� 'warp'
function i = getDoFName(i)
	switch(i)
		case 1 i = 'disp_x';
		case 2 i = 'disp_y';
		case 3 i = 'disp_z';
		case 4 i = 'rot_x';
		case 5 i = 'rot_y';
		case 6 i = 'rot_z';
		case 7 i = 'warp';
		otherwise error(['��� ������� DoF �� index ', num2str(i)]);
	endswitch
endfunction

% �������� ��� index ���� ������ ���������� ��� ���� ���.
% in: i: �� index ��� ������
% out: i: �� ����� ��� ����� ��� ������ �.�. '�����'
function i = getElementType(i)
	switch(i)
		case 0 i = '������';
		case 1 i = '�������� ��������';
		case 2 i = '�������� ��������';
		case 3 i = '�����';
		otherwise error(['��� ������� ����� ������ �� index ', num2str(i)]);
	endswitch
endfunction

% ������� ��� ������������� �� ������ html
% in: filename: �� ����� ������� ������ (html)
function exportReport(filename)
	global data;
	fp = fopen(filename, 'w');
	fwrite(fp, "<html>\r\n");
	fwrite(fp, "<head>\r\n");
	fwrite(fp, "<meta charset=\"UTF-8\">\r\n");
	fwrite(fp, "<title>������������ ��������</title>\r\n\r\n");
	fwrite(fp, "<style>\r\n");	% CSS Stylesheets
	fwrite(fp, "table { border-collapse: collapse; }\r\n");
	fwrite(fp, "th, td { border: 1px solid black; }\r\n");
	fwrite(fp, "tbody>tr.even { background-color: #eee; }\r\n");
	fwrite(fp, "tbody>tr:hover { background-color: #cec; }\r\n");
	fwrite(fp, "</style>\r\n");
	fwrite(fp, "</head>\r\n\r\n");
	fwrite(fp, "<body>\r\n\r\n");
	% ������� ��������� ��� ������
	fwrite(fp, "<h1>������</h1>\r\n\r\n");
	fwrite(fp, "<table>\r\n<thead>\r\n<tr><th>������</th><th>������ ����������</th><th>��������� ����������</th><th>������ ����</th><th>����������</th><th>������ ����</th><th>������</th><th>���������</th><th>�����</th></tr>\r\n</thead>\r\n<tbody>\r\n");
	for i = 1:length(data.nodes);
		n = data.nodes{i};
		for j = 1:7
			row = n.dofs(j);	% 0: ��� �������, >0: ���������, <0: �����������
			if (row)
				if (mod(i, 2)) p = '<tr>'; else p = '<tr class="even">'; endif
				fwrite(fp, p);
				fwrite(fp, ['<td>', n.id, '</td>']);
				fwrite(fp, ['<td>', getDoFName(j), '</td>']);
				% ����������� ������ ����������
				if (row < 0) p = '���'; else p = '���'; endif
				fwrite(fp, ['<td>', num2str(p), '</td>']);
				% ������ ���� ������ ����������, ���������� ��� ������ ����
				if (j <= 3) p = num2str(n.coords(j)); else p = ''; endif
				fwrite(fp, ['<td>', p, '</td>']);
				p = num2str(n.displacements(j));	% ��������������� ��� ���� ������ ����
				fwrite(fp, ['<td>', p, '</td>']);
				if (j <= 3) p = num2str(n.coords(j) + n.displacements(j)); endif
				fwrite(fp, ['<td>', p, '</td>']);
				% ��������� ������ ����� �����������, ����������� ��� �������� �����
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
	% ������� ��������� ��� �����
	fwrite(fp, "<h1>����</h1>\r\n\r\n");
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


% ============================================= � ������ ������ ��� ������������


try

	% �������� �� ������ xml �� �� �����
	[file, path] = uigetfile('*.xml', '����� �� ������ XML ��� �����');
	if (~file) return; endif;
	parseXML([path, file]);
	% ���������� ��� ��������� G ��� ������
	calcMaterialProperties();
	% ���������� ��� ��������� A, Iy, Iz, It, Cs ��� ��������
	calcFrameSectionsProperties();
	% ��������� �� ��������� ������ ����� �������
	calcNodalLoads();
	% ���������� �� ������ ���������� ��� ��������� ����� ��� ����� ������� ��������
	% ���������� ���� ������� ��� ���� DoFs ��� �������������
	calcElementsStiffness();

	%{
	�� ������ ���������� ��� ����� ������������ ��������.
	+---+---+---+
	�K11�K12�K13�
	+---+---+---+
	�K21� 0 �K23�
	+---+---+---+
	�K31�K32�K33�
	+---+---+---+
	�11: �� ��������� ������ ���������� ��� �����.
	�33: �� ����������� ������ ���������� ��� �����.
	K13: � ����� ���������.
	�31: � ���������� ��� �13. ��� �������������. ��������������� � K13' ��� ���� ���.
	�21: �� ������ ��������� �� ���� ���� ���������� ������� ���������� ��� �����,
				��� ������� � ��� ��������������� Lagrange.
	�23: �� ������ ��������� �� ���� ���� ������������ ������� ���������� ��� �����,
				��� ������� � ��� ��������������� Lagrange.
	�12: � ���������� ��� �21. ������������ ���� ����������� � �21.
	�32: � ���������� ��� �23. ��� �������������. ��������������� � �32' ��� ���� ���.
	0: ��������� �������.
	�11,�12,�21,0: �� ��������� ������ ���������� ��� �����, ���� �� ��� �������
				��������������� Lagrange.
	K13,K23:
	%}

	% ����� ��������� ��������������� Lagrange �� ���������� ��� ������
	data.solver.totalLagrangeEquations = 0;
	% ��������� ��� restraints �� constraints, ��� ����� � ��� ����������� �����
	convertRestraintsToConstraints();
	%����������� ��� constraints
	linkConstrainedDoFs();
	% ���������� �� ���������� ����������� �� indices 1,2,3,.. ��� ���� ����������
	% ������� ���������� ��� -1,-2,-3,... ��� ���� ������������.
	makePermutationLookupTableOnNodes();
	% ���������� ���� 3 ������� ��� ������� ���������� ��� �����, ����� ��� �� ����������
	initStructureStiffness();
	% ����������� ���� 3 ������� ��� ������� ���������� ��� �����, ���� ��� �� ��������
	populateStructureStiffnessFromElements();
	% ����������� �� ��������� ���������� (������ ��� ������������) ��� ���� �������
	populateStructureStiffnessFromNodes();
	% ����������� ��� ������ ���������� ��� �����, ��� ��������� ���������������
	% Lagrange ��� ������������ (constraints)
	populateStructureStiffnessFromConstraints();
	% ������� � ������ ���������
	solveStructure();
	% �� ������ ������������� ��� ��� ������������ ����� ������� ���������� ���
	% ��� ����������� ��� ����������
	outputToNodes();
	% �� �������� ������������� ��� ��� ������������ ����� �������� ������� ����������
	% ��� �� ������ ��� ������
	outputToElements();
	% �������������� ������� ��� ���� �������� ��� ������ ��� ����������� ��� ���������
	% �� �������
	outputElementsFunctions();
	% ������� ������� ������
	[file, path] = uiputfile('*.html', '����� �� ������ ����������� ��� �������������', path);
	if (~file) file = "export.html"; endif;
	exportReport([path, file]);
	%exportFigures(data);

catch err
	opt.Interpreter = 'none'; opt.WindowStyle = 'modal';
	errordlg(err.message, "������", opt);
	error(err);
end_try_catch;