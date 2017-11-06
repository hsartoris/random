'''

Limitations: readout spacing is occasionally useless and misaligns lookaheads.
Don't feel like digging around ncurses though.

All terminals and nonterminals must be one character. Additionally, any
uppercase character is assumed to be a nonterminal, and vice versa.

All rules must start with something of the form A::=

'''
# for making the DFA
#import numpy as np
#import networkx as nx

rules = [ "S::=E$", "E::=E+T", "E::=T", "T::=T*F", "T::=F", "F::=(E)", "F::=i" ]

#rules = [ "E::=E_E^E", "E::=_E", "E::=E^E", "E::=(E)", "E::=c" ]

states = []

verbose = True

class Item:
	def __init__(self, str, z):
		# hacky but works
		self.string = str
		self.z = z
		self.LHS = self.string[:4]
		tail = self.string[4:].split('.')
		if len(tail[1]) == 0 or not tail[1][0].isupper():
			self.hasClosure = False
			self.closed = True
		else:
			self.hasClosure = True
			self.closed = False

		self.alpha = tail[0]
		if len(tail[1]) > 0:
			self.X = tail[1][0]
			self.beta = tail[1][1:]
		else:
			self.X = ''
			self.beta = ''
		self.F = self.first(self.beta + self.z)

	def closure(self, items):
		global rules
		for rule in rules:
			if rule[0] == self.X:
				item = Item(rule[:4] + "." + rule[4:], self.F)
				if not item in items:
					items.append(item)
		return items

	def first(self, bz):
		return bz[0]

	def __eq__(self, other):
		return self.string == other.string and self.z == other.z

	def __str__(self):
		if not self.hasClosure or not verbose: return self.string + "\t\t" + self.z
		return self.string.ljust(20) + "\t" + self.z + "\t" + self.alpha + "\t" + self.X + "\t" + self.beta + "\t" + self.z + "\t" + self.F

class State:
	def __init__(self, i):
		self.closure = []
		if isinstance(i, Item):
			i.closed = False
			self.closure.append(i)
		else:
			for item in i:
				item.closed = False
				self.closure.append(item)
		self.doClosure()
		self.simpleClosure()
		self.shifts = []
		for c in self.closure:
			if not c.X in self.shifts and not c.X == '':
				self.shifts.append(c.X)
		self.shifted = False

	def simpleClosure(self):
		self.simple = []
		for i1 in self.closure:
			added = False
			for i2 in self.simple:
				if i1.string == i2.string and i1.z not in i2.z:
					i2.z += ", " + i1.z
					added = True
			if not added:
				self.simple.append(Item(i1.string, i1.z))

	def doClosure(self):
		closureLen = 0
		while not closureLen == len(self.closure):
			closureLen = len(self.closure)
			for item in self.closure:
				if item.hasClosure and not item.closed:
					self.closure = item.closure(self.closure)
					item.closed = True
	def shift(self):
		global states
		# also GOTO
		self.shiftRules = [-1] * len(self.shifts)
		for i in range(len(self.shifts)):
			s = self.shifts[i]
			items = []
			for item in self.closure:
				if item.X == s:
					str = item.LHS + item.alpha + item.X + "." + item.beta
					items.append(Item(str, item.z))
			newState = State(items)
			for j in range(len(states)):
				if states[j] == newState:
					self.shiftRules[i] = j
					break
			if self.shiftRules[i] == -1:
				states.append(newState)
				self.shiftRules[i] = len(states)-1
		self.shifted = True

	def simpleStr(self):
		temp = ''
		for c in self.simple:
			temp += str(c) + "\n"
		temp += "\n"
		if len(self.shifts) > 0:
			temp += "Shifts: \n"
			for i in range(len(self.shifts)):
				temp += self.shifts[i] + ": " + str(self.shiftRules[i]+1) + "\n"
		return temp

	def __str__(self):
		temp = ''
		for c in self.closure:
			temp += str(c) + "\n"
		temp += "\n"
		#if len(self.shifts) > 0:
		#	temp += "Shifts: \n"
		#	for i in range(len(self.shifts)):
		#		temp += self.shifts[i] + ": " + str(self.shiftRules[i]+1) + "\n"
		return temp

	def __eq__(self, other):
		if not len(self.closure) == len(other.closure): return False
		for c in self.closure:
			if not c in other.closure:
				return False
		return True

	def strShifts(self):
		temp = ''
		for s in self.shifts:
			temp += s + ", "
		return temp

def makeItem():
	return Item("S::=.E$", "?")
	#return Item("S::=.E$", "?")

def doStates():
	states.append(State(makeItem()))
	stateCount = 0
	while not stateCount == len(states):
		stateCount = len(states)
		for state in states:
			if not state.shifted:
				state.shift()

def printStates():
	global states
	for i in range(len(states)):
		print("-"*65 + "\n")
		print("State " + str(i + 1) + ":")
		if not verbose: print("string\tlookahead")
		else: print("string\t\tlookahead\talpha\tX\tbeta\tz\tF")
		print(states[i])
		print("-"*35)
		print("Condensed state: ")
		print(states[i].simpleStr())
	print("Note that the accept state is included here, increasing count by 1.")

def printSimple():
	global states
	global verbose
	verbose = False
	print(("-"*35 + "\n")*2)
	print("Condensed states start here")
	for i in range(len(states)):
		print("-"*35 + "\n")
		print("State " + str(i + 1) + ":")
		print(states[i].simpleStr())

def makeAdjacency():
	global states
	out = np.zeros(shape=(len(states)+1, len(states)+1))
	for i in range(len(states)):
		for shift in states[i].shiftRules:
			out[i+1][shift+1] = 1
	return np.matrix(out)

def graphMatrix(w):
	Gx = nx.drawing.nx_pydot.to_pydot(nx.DiGraph(w))
	Gx.write_png("DFA.png", prog='dot')


if __name__ == "__main__":
	doStates()
	printStates()
	#graphMatrix(makeAdjacency())
	# prints simple states
	#printSimple()
#i = makeItem()
#i.C = i.closure([])
#s = State(i)
