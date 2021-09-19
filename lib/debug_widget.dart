part of proba_sdk_flutter;

class _DebugWidget extends StatefulWidget {
  final bool _isOptionsLoaded;
  final List<Map<String, dynamic>> _experimentsOptions;
  final Map<String, String> _debugExperiments;
  final Map<String, String> _experiments;
  final Function(bool loaded) _optionsLoadedSetter;
  final Function _experimentsOptionsLoader;
  final ExperimentsChangedCallback _valuesChangedCallback;

  _DebugWidget({
    @required bool isOptionsLoaded,
    @required List<Map<String, dynamic>> experimentsOptions,
    @required Map<String, String> debugExperiments,
    @required Map<String, String> experiments,
    @required Function(bool loaded) optionsLoadedSetter,
    @required Function experimentsOptionsLoader,
    @required valuesChangedCallback,
  })  : _isOptionsLoaded = isOptionsLoaded,
        _experimentsOptions = experimentsOptions,
        _debugExperiments = debugExperiments,
        _experiments = experiments,
        _optionsLoadedSetter = optionsLoadedSetter,
        _experimentsOptionsLoader = experimentsOptionsLoader,
        _valuesChangedCallback = valuesChangedCallback;

  @override
  _DebugWidgetState createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<_DebugWidget> {
  bool _isOptionsLoaded;
  List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    _isOptionsLoaded = widget._isOptionsLoaded;
    if (_isOptionsLoaded) {
      _expanded = List<bool>.generate(
          widget._experimentsOptions.length, (index) => false);
      return;
    }
    _loadExperimentsOptions();
  }

  void _resetExperiments() {
    setState(() {
      _clearDebugExperiments();
    });
  }

  void _reloadExperiments() {
    setState(() {
      _isOptionsLoaded = false;
      _clearDebugExperiments();
    });
    _loadExperimentsOptions();
  }

  void _clearDebugExperiments() {
    final debugKeys = widget._debugExperiments.keys.toList(growable: false);
    widget._debugExperiments.clear();
    if (widget._valuesChangedCallback != null) {
      widget._valuesChangedCallback(debugKeys);
    }
  }

  Future<void> _loadExperimentsOptions() async {
    final options = await widget._experimentsOptionsLoader(
      knownExperimentsKeys: widget._experiments.keys.toList(growable: false),
    );
    if (!mounted) return;

    widget._experimentsOptions.clear();
    widget._experimentsOptions.addAll(options);
    widget._optionsLoadedSetter(true);
    setState(() {
      _isOptionsLoaded = true;
      _expanded = List<bool>.generate(
          widget._experimentsOptions.length, (index) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.8,
      widthFactor: 1.0,
      child: AnimatedCrossFade(
        duration: kThemeChangeDuration,
        crossFadeState: _isOptionsLoaded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: Container(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
        secondChild: IgnorePointer(
          ignoring: !_isOptionsLoaded,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text('Reset'),
                      onPressed: _resetExperiments,
                    ),
                    TextButton(
                      child: Text('Reload'),
                      onPressed: _reloadExperiments,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  primary: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'A/B-tests',
                              style: theme.textTheme.headline4
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "In debug mode, you can:\n1. See available experiments for this app build\n2. View all options as users see them",
                                style: theme.textTheme.bodyText2,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text('AVAILABLE EXPERIMENTS'),
                            ),
                          ],
                        ),
                      ),
                      ExpansionPanelList(
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            _expanded[index] = !isExpanded;
                          });
                        },
                        children: widget._experimentsOptions
                            .map<ExpansionPanel>((experiment) {
                          final key = experiment["key"].toString();
                          final selectedOption =
                              widget._debugExperiments[key] ??
                                  widget._experiments[key];
                          return ExpansionPanel(
                            canTapOnHeader: true,
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                title: Text(experiment["name"].toString()),
                              );
                            },
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: (experiment['options'] as List)
                                  .map<ListTile>((option) {
                                final value = option['value'].toString();
                                return ListTile(
                                  leading: Radio<String>(
                                    value: option['value'].toString(),
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setState(() {
                                        widget._debugExperiments[key] = value;
                                        if (widget._valuesChangedCallback !=
                                            null) {
                                          widget._valuesChangedCallback([key]);
                                        }
                                      });
                                    },
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget._experiments[key] == value)
                                        Text(
                                          'Received option',
                                          style:
                                              theme.textTheme.overline.copyWith(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(option['description'].toString()),
                                    ],
                                  ),
                                  subtitle: Text(value),
                                  isThreeLine: true,
                                );
                              }).toList(),
                            ),
                            isExpanded: _expanded.asMap()[widget
                                    ._experimentsOptions
                                    .indexOf(experiment)] ??
                                false,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        layoutBuilder: (topChild, _topChildKey, bottomChild, _bottomChildKey) {
          return Stack(
            children: <Widget>[
              ConstrainedBox(
                child: bottomChild,
                constraints: BoxConstraints.tightForFinite(),
              ),
              ConstrainedBox(
                child: topChild,
                constraints: BoxConstraints.tightForFinite(),
              )
            ],
          );
        },
      ),
    );
  }
}
