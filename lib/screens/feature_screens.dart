import 'dart:convert';
import 'package:flutter/material.dart';
import 'assignment_media_screen.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../services/settings_service.dart';
import '../main.dart';

class _Base extends StatelessWidget {
  final String title; final Widget child;
  const _Base({required this.title, required this.child});
  @override Widget build(BuildContext c) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent, elevation: 0),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) => AnimatedMeshBackground(
          enabled: effectsOn, primary: primary, secondary: secondary,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 72, 12, 12),
              child: GlassCard(blurEnabled: effectsOn, padding: const EdgeInsets.all(10), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class ClassesScreen extends StatefulWidget { const ClassesScreen({super.key}); @override State<ClassesScreen> createState()=>_ClassesScreenState(); }
class _ClassesScreenState extends State<ClassesScreen> {
  List _items=[]; List _teachers=[]; bool loading=true;
  Future<void> load() async {
    final r=await ApiService.get('manager/list-classes');
    final t=await ApiService.get('manager/list-teachers');
    if(mounted)setState(()=>{_items=r['success']==true?r['data']:[], _teachers=t['success']==true?t['data']:[], loading=false});
  }
  @override void initState(){super.initState();load();}
  Future<void> add() async {
    final n=TextEditingController(), g=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
      title:const Text('افزودن کلاس'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'نام کلاس')),
        TextField(controller:g,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'پایه')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ثبت'))]
    ));
    if(ok==true){final r=await ApiService.post('manager/add-class',{'name':n.text.trim(),'grade_level':int.tryParse(g.text)??1},auth:true); if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'ثبت شد':'خطا'))));} if(r['success']==true)load();}
  }
  Future<void> deleteClass(dynamic classItem) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('حذف کلاس'), content: Text('کلاس «${classItem['name']}» حذف شود؟ سوابق تکالیف و نمره‌ها در بایگانی می‌مانند.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف کلاس'))]));
    if (yes != true) return;
    final r = await ApiService.post('manager/delete-class', {'class_id': classItem['id']}, auth: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? (r['success'] == true ? 'کلاس حذف شد' : 'خطا'))));
    if (r['success'] == true) load();
  }
  Future<void> assignTeacher(dynamic classItem) async {
    if(_teachers.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا یک استاد اضافه کنید')));return;}
    int? teacherId;
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(ctx,setDialogState)=>AlertDialog(
      title:Text('انتخاب استاد برای ${classItem['name']}'),
      content:DropdownButtonFormField<int>(
        value:teacherId,
        items:_teachers.map<DropdownMenuItem<int>>((t)=>DropdownMenuItem(value:t['id'],child:Text(t['full_name']??''))).toList(),
        onChanged:(v)=>setDialogState(()=>teacherId=v),
        decoration:const InputDecoration(labelText:'استاد'),
      ),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('لغو')),FilledButton(onPressed:()=>teacherId==null?null:Navigator.pop(ctx,true),child:const Text('تخصیص'))],
    )));
    if(ok==true && teacherId!=null){
      final r=await ApiService.post('manager/assign-teacher',{'class_id':classItem['id'],'teacher_id':teacherId},auth:true);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'استاد به کلاس تخصیص داده شد':'خطا'))));
      load();
    }
  }
  String teachersFor(dynamic classItem){
    final ids=<String>[];
    for(final t in _teachers){
      final cs=t['classes'];
      if(cs is List && cs.any((c)=>'${c['id']}'=='${classItem['id']}')) ids.add(t['full_name']??'');
    }
    return ids.isEmpty?'استادی برای این کلاس تعیین نشده': 'استاد: ${ids.join('، ')}';
  }
  @override Widget build(BuildContext c)=>_Base(title:'کلاس‌ها',child:loading?const Center(child:CircularProgressIndicator()):Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Align(alignment:Alignment.centerLeft,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('کلاس جدید')))),
    Expanded(child:ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final x=_items[i];return Card(child:ListTile(
      title:Text(x['name']??''),
      subtitle:Text('پایه ${x['grade_level']}  •  کد ${x['class_code']}\n${teachersFor(x)}'),
      isThreeLine:true,
      leading:const Icon(Icons.meeting_room),
      trailing:Wrap(children:[IconButton(tooltip:'تعیین استاد',icon:const Icon(Icons.person_add_alt_1_rounded),onPressed:()=>assignTeacher(x)),IconButton(tooltip:'حذف کلاس',icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent),onPressed:()=>deleteClass(x))]),
    ));}))
  ]));
}

class ArchiveScreen extends StatefulWidget { const ArchiveScreen({super.key}); @override State<ArchiveScreen> createState()=>_ArchiveScreenState(); }
class _ArchiveScreenState extends State<ArchiveScreen>{List _items=[];bool loading=true;Future<void> load()async{final r=await ApiService.get('archive/list',auth:true);if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});}
@override void initState(){super.initState();load();}
@override Widget build(BuildContext c)=>_Base(title:'بایگانی تکالیف و نمره‌ها',child:loading?const Center(child:CircularProgressIndicator()):_items.isEmpty?const Center(child:Text('هنوز موردی در بایگانی نیست')):ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final x=_items[i];final results=(x['results'] as List?)??[];return Card(child:ExpansionTile(leading:Icon(x['event_type']=='class_deleted'?Icons.meeting_room_outlined: x['event_type']=='voice_or_media_deleted'?Icons.audio_file_outlined:Icons.archive_outlined),title:Text(x['title']??'سابقه'),subtitle:Text('${x['created_at']??''} • ${x['actor_name']??'کاربر'}'),children:[if(x['details']!=null)Padding(padding:const EdgeInsets.all(12),child:Text('${x['details']}')),if(x['file_path']!=null)Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('رسانه محفوظ در بایگانی'),AssignmentMediaList(attachments:[{'file_path':x['file_path'],'media_type':((){try{return (jsonDecode('${x['details']}') as Map)['media_type']??'audio';}catch(_){return 'audio';}})()}])])),if(results.isNotEmpty)...results.map((r)=>ListTile(leading:const Icon(Icons.assignment_turned_in_outlined),title:Text(r['student_name']??'قرآن‌آموز'),subtitle:Text('نمره: ${r['score']??'ثبت نشده'} • تلاش ${r['attempt_number']??1} • ${r['created_at']??''}')))]));}));}

class PeopleScreen extends StatefulWidget { final bool teachers; const PeopleScreen({super.key,required this.teachers}); @override State<PeopleScreen> createState()=>_PeopleScreenState(); }
class _PeopleScreenState extends State<PeopleScreen>{List _items=[];List _classes=[];bool loading=true;
 Future<void> load()async{final r=await ApiService.get(widget.teachers?'manager/list-teachers':'manager/list-students');final c=await ApiService.get('manager/list-classes');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],_classes=c['success']==true?c['data']:[],loading=false});}
 @override void initState(){super.initState();load();}
 Future<void> add()async{final name=TextEditingController(),u=TextEditingController(),p=TextEditingController();int? cid;final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,s)=>AlertDialog(title:Text(widget.teachers?'افزودن استاد':'افزودن قرآن آموز'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'نام و نام خانوادگی')),TextField(controller:u,decoration:const InputDecoration(labelText:'نام کاربری')),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور')),if(!widget.teachers)DropdownButtonFormField<int>(value:cid,items:_classes.map<DropdownMenuItem<int>>((x)=>DropdownMenuItem(value:x['id'],child:Text(x['name']))).toList(),onChanged:(v)=>s(()=>cid=v),decoration:const InputDecoration(labelText:'کلاس'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ثبت'))])));if(ok==true){final body={'full_name':name.text.trim(),'username':u.text.trim(),'password':p.text.trim(),if(!widget.teachers)'class_id':cid};final r=await ApiService.post(widget.teachers?'manager/add-teacher':'manager/add-student',body,auth:true);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'ثبت شد':'خطا'))));if(r['success']==true)load();}}
 @override Widget build(BuildContext c)=>_Base(title:widget.teachers?'استادها':'قرآن آموزان',child:loading?const Center(child:CircularProgressIndicator()):Column(children:[Padding(padding:const EdgeInsets.all(12),child:Align(alignment:Alignment.centerLeft,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.person_add),label:const Text('افزودن')))),Expanded(child:ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final x=_items[i];return Card(child:ListTile(title:Text(x['full_name']??''),subtitle:Text('${x['username']??''}${x['class_name']!=null?' • ${x['class_name']}':''}'),leading:Icon(widget.teachers?Icons.person:Icons.menu_book)));}))]));
}

class AnnouncementsScreen extends StatefulWidget { final bool student; const AnnouncementsScreen({super.key,this.student=false}); @override State<AnnouncementsScreen> createState()=>_AnnouncementsScreenState(); }
class _AnnouncementsScreenState extends State<AnnouncementsScreen>{List _items=[];bool loading=true;Future<void>load()async{final r=await ApiService.get(widget.student?'student/list-announcements':'manager/list-announcements');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});} @override void initState(){super.initState();load();}
 Future<void> add()async{final t=TextEditingController(),b=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('اطلاعیه جدید'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:t,decoration:const InputDecoration(labelText:'عنوان')),TextField(controller:b,maxLines:4,decoration:const InputDecoration(labelText:'متن'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ارسال'))]));if(ok==true){final r=await ApiService.post('manager/add-announcement',{'title':t.text.trim(),'content':b.text.trim()},auth:true);if(r['success']==true)load();}}
 @override Widget build(BuildContext c)=>_Base(title:'اطلاعیه‌ها',child:loading?const Center(child:CircularProgressIndicator()):Column(children:[if(!widget.student)Padding(padding:const EdgeInsets.all(12),child:Align(alignment:Alignment.centerLeft,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('اطلاعیه جدید')))),Expanded(child:ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final x=_items[i];return Card(child:ListTile(title:Text(x['title']??''),subtitle:Text(x['content']??''),isThreeLine:true));}))]));}

class TeacherClassesScreen extends StatefulWidget{const TeacherClassesScreen({super.key});@override State<TeacherClassesScreen>createState()=>_TeacherClassesScreenState();}
class _TeacherClassesScreenState extends State<TeacherClassesScreen>{
  List _items=[]; bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load()async{final r=await ApiService.get('teacher/list-classes');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});}
  @override
  Widget build(BuildContext c) {
    return _Base(
      title: 'کلاس‌های من',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final x = _items[i];
                return Card(
                  child: ListTile(
                    title: Text(x['name'] ?? ''),
                    subtitle: Text('پایه ${x['grade_level']} • کد ${x['class_code']}'),
                    leading: const Icon(Icons.meeting_room_rounded),
                    onTap: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => TeacherClassDetail(
                          classId: x['id'],
                          name: x['name'] ?? '',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TeacherClassDetail extends StatefulWidget{final dynamic classId;final String name;const TeacherClassDetail({super.key,required this.classId,required this.name});@override State<TeacherClassDetail>createState()=>_TeacherClassDetailState();}
class _TeacherClassDetailState extends State<TeacherClassDetail>{
  List _students=[]; List _assign=[]; bool loading=true;
  Future<void> load()async{final a=await ApiService.get('teacher/list-students?class_id=${widget.classId}');final b=await ApiService.get('teacher/list-assignments?class_id=${widget.classId}');if(mounted)setState(()=>{_students=a['success']==true?a['data']:[],_assign=b['success']==true?b['data']:[],loading=false});}
  @override void initState(){super.initState();load();}
  Future<void> deleteAssignment(dynamic assignment) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('انتقال تکلیف به بایگانی'), content: Text('«${assignment['title']}» از فهرست حذف شود؟ نمره‌ها، ویس‌ها و تحویل‌ها حفظ می‌شوند.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))]));
    if (yes != true) return;
    final r = await ApiService.post('teacher/delete-assignment', {'assignment_id': assignment['id']}, auth: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? (r['success'] == true ? 'به بایگانی منتقل شد' : 'خطا'))));
    if (r['success'] == true) load();
  }
  Future<void> publishReport(dynamic student) async { final r=await ApiService.post('report/publish',{'student_id':student['id']},auth:true); if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'کارنامه ارسال شد':'خطا')))); }
  @override Widget build(BuildContext c)=>_Base(title:widget.name,child:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(12),children:[
    const Text('قرآن آموزان',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    ..._students.map(
      (x) => Card(
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(x['full_name'] ?? ''),
          subtitle: Text(x['username'] ?? ''),
          trailing: IconButton(
            tooltip: 'صدور کارنامه',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => publishReport(x),
          ),
        ),
      ),
    ),
    const Divider(),
    const Text('تکالیف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ..._assign.map(
      (x) => Card(
        child: ListTile(
          leading: const Icon(Icons.assignment_rounded),
          title: Text(x['title'] ?? ''),
          subtitle: Text('کد ${x['assignment_code'] ?? ''} • مهلت: ${x['due_date'] ?? 'بدون مهلت'}'),
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => AssignmentSubmissionsScreen(assignment: x),
            ),
          ),
          trailing: IconButton(tooltip: 'حذف و بایگانی', icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => deleteAssignment(x)),
        ),
      ),
    ),
  ]));
}

class AssignmentSubmissionsScreen extends StatefulWidget{final dynamic assignment;const AssignmentSubmissionsScreen({super.key,required this.assignment});@override State<AssignmentSubmissionsScreen>createState()=>_AssignmentSubmissionsScreenState();}
class _AssignmentSubmissionsScreenState extends State<AssignmentSubmissionsScreen>{List _items=[];bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load()async{final r=await ApiService.get('teacher/list-submissions?assignment_id=${widget.assignment['id']}');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});}
  Future<void> deleteSubmissionMedia(dynamic a) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('حذف رسانه'), content: const Text('این ویس یا فایل از فهرست عادی حذف می‌شود، اما نسخه آن در بایگانی برای مدیر و استاد حفظ خواهد شد.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف و بایگانی'))]));
    if (yes != true) return;
    final r = await ApiService.post('teacher/delete-media', {'owner_type': 'submission', 'attachment_id': a['id']}, auth: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? (r['success'] == true ? 'در بایگانی ذخیره شد' : 'خطا'))));
    if (r['success'] == true) { Navigator.of(context).pop(); load(); }
  }
  Future<void> grade(dynamic x)async{final controller=TextEditingController(text:x['score']==null?'':'${x['score']}');final result=await showDialog<Map<String,dynamic>>(context:context,builder:(d)=>AlertDialog(title:Text('بررسی تکلیف ${x['student_name']}'),content:TextField(controller:controller,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'نمره از ${widget.assignment['max_score']??20}')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('لغو')),TextButton(onPressed:()=>Navigator.pop(d,{'resubmit':true}),child:const Text('درست نیست؛ ارسال مجدد')),FilledButton(onPressed:()=>Navigator.pop(d,{'score':double.tryParse(controller.text)}),child:const Text('ثبت نمره'))]));if(result==null)return;final r=await ApiService.post('teacher/grade-submission',{'submission_id':x['submission_id'],'request_resubmit':result['resubmit']==true,'score':result.containsKey('score')?result['score']:null},auth:true);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?(result['resubmit']==true?'برای قرآن‌آموز درخواست ارسال مجدد ثبت شد':'نمره ثبت شد'):'خطا'))));if(r['success']==true)load();}
  @override
  Widget build(BuildContext c) {
    return _Base(
      title: 'تحویل‌های ${widget.assignment['title']}',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final x = _items[i];
                return Card(
                  child: ListTile(
                    title: Text(x['student_name'] ?? ''),
                    subtitle: Text(
                      '${x['attempt_number'] != null && (int.tryParse('${x['attempt_number']}') ?? 1) > 1 ? 'ارسال مجدد (${(int.tryParse('${x['attempt_number']}') ?? 2) - 1}) • ' : ''}${x['status'] == 'resubmit_requested' ? 'نیازمند ارسال مجدد • ' : ''}${x['is_late'] == 1 ? 'دیرکرد: ${x['late_days']} روز • ' : ''}${x['score'] ?? 'بدون نمره'}',
                    ),
                    leading: Icon(
                      x['is_late'] == 1
                          ? Icons.warning_amber_rounded
                          : Icons.assignment_turned_in_rounded,
                    ),
                    onTap: () => showDialog(
                      context: c,
                      builder: (_) => AlertDialog(
                        title: Text(x['student_name'] ?? ''),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if ((x['content'] ?? '').toString().isNotEmpty)
                                Text(x['content']),
                              AssignmentMediaList(attachments: x['attachments'] ?? [], attemptNumber: int.tryParse('${x['attempt_number'] ?? 1}') ?? 1, onDelete: deleteSubmissionMedia),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('بستن'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(c);
                              grade(x);
                            },
                            child: const Text('نمره‌دهی'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget{final String schoolId;final String schoolName;const AdminSettingsScreen({super.key,required this.schoolId,required this.schoolName});@override State<AdminSettingsScreen>createState()=>_AdminSettingsScreenState();}
class _AdminSettingsScreenState extends State<AdminSettingsScreen>{Map<String,bool> f={};final limit=TextEditingController();String p='#2F5FFF',s='#FFB020';@override void initState(){super.initState();load();}Future<void>load()async{final r=await ApiService.get('admin/list-school-features?school_id=${widget.schoolId}');if(r['success']==true&&r['data'] is List){for(final x in r['data'])f[x['feature_key']]=(x['enabled']==1||x['enabled']==true);}final schools=await ApiService.get('admin/list-schools');if(schools['success']==true){for(final x in schools['data'])if('${x['id']}'==widget.schoolId){limit.text='${x['free_message_limit']??1}';p=x['theme_primary_color']??p;s=x['theme_secondary_color']??s;}}if(mounted)setState((){});}Future<void>saveFeature(String k,bool v)async{final r=await ApiService.post('admin/set-school-feature',{'school_id':int.tryParse(widget.schoolId)??widget.schoolId,'feature_key':k,'enabled':v},auth:true);if(r['success']!=true&&mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'خطا')));}Future<void>saveLimit()async{final r=await ApiService.post('admin/set-school-settings',{'school_id':int.tryParse(widget.schoolId)??widget.schoolId,'free_message_limit':int.tryParse(limit.text)??1},auth:true);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'ذخیره شد':'خطا'))));}
@override Widget build(BuildContext c)=>_Base(title:'تنظیمات ${widget.schoolName}',child:ListView(padding:const EdgeInsets.all(16),children:[const Text('قابلیت‌ها',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...['exams','late_penalty','resubmit','points'].map((k)=>SwitchListTile(title:Text(k),value:f[k]??true,onChanged:(v){setState(()=>f[k]=v);saveFeature(k,v);})),TextField(controller:limit,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'تعداد پیام آزاد قرآن آموز')),const SizedBox(height:12),FilledButton(onPressed:saveLimit,child:const Text('ذخیره تنظیمات پیام'))]));}

class AddAssignmentScreen extends StatefulWidget{const AddAssignmentScreen({super.key});@override State<AddAssignmentScreen>createState()=>_AddAssignmentScreenState();}
class _AddAssignmentScreenState extends State<AddAssignmentScreen>{
  List _classes=[];int? cid;final title=TextEditingController(),desc=TextEditingController(),score=TextEditingController(text:'20'),days=TextEditingController(text:'2'),penalty=TextEditingController(text:'1');List<String> files=[];bool loading=true,saving=false;
  @override void initState(){super.initState();load();}
  Future<void> load()async{final r=await ApiService.get('teacher/list-classes');if(mounted)setState(()=>{_classes=r['success']==true?r['data']:[],loading=false});}
  Future<void> save()async{if(cid==null||title.text.trim().isEmpty)return;setState(()=>saving=true);final r=await ApiService.uploadMultipartMany('teacher/add-assignment',{'class_id':'$cid','title':title.text.trim(),'description':desc.text.trim(),'max_score':score.text.trim(),'due_days':days.text.trim(),'late_penalty':penalty.text.trim()},filePaths:files);if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'تکلیف ثبت شد':'خطا'))));if(r['success']==true)Navigator.pop(context,true);}}
  @override Widget build(BuildContext c)=>_Base(title:'تکلیف جدید',child:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[DropdownButtonFormField<int>(value:cid,items:_classes.map<DropdownMenuItem<int>>((x)=>DropdownMenuItem(value:x['id'],child:Text(x['name']))).toList(),onChanged:(v)=>setState(()=>cid=v),decoration:const InputDecoration(labelText:'کلاس')),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان تکلیف')),TextField(controller:desc,maxLines:5,decoration:const InputDecoration(labelText:'متن تکلیف / توضیحات')),TextField(controller:score,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'نمره کل')),Row(children:[Expanded(child:TextField(controller:days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مهلت (روز)'))),const SizedBox(width:10),Expanded(child:TextField(controller:penalty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'کسر نمره برای هر روز دیرکرد')))]),const SizedBox(height:12),MediaPickerPanel(onChanged:(v)=>setState(()=>files=v)),const SizedBox(height:18),FilledButton(onPressed:saving?null:save,child:Text(saving?'در حال ارسال...':'انتشار تکلیف'))]));
}

class AssignmentScreen extends StatefulWidget{const AssignmentScreen({super.key});@override State<AssignmentScreen>createState()=>_AssignmentScreenState();}
class _AssignmentScreenState extends State<AssignmentScreen>{List _items=[];bool loading=true;@override void initState(){super.initState();load();}Future<void>load()async{final r=await ApiService.get('student/list-assignments');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});}
  @override
  Widget build(BuildContext c) {
    return _Base(
      title: 'ارسال تکالیف',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final x = _items[i];
                return Card(
                  child: ListTile(
                    title: Text(x['title'] ?? ''),
                    subtitle: Text(
                      '${x['teacher_name'] ?? ''} • ${x['submitted'] == 1 ? 'تحویل شده' : 'تحویل نشده'} • مهلت: ${x['due_date'] ?? 'بدون مهلت'}',
                    ),
                    leading: const Icon(Icons.assignment_rounded),
                    onTap: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => StudentAssignmentDetail(assignment: x),
                      ),
                    ).then((_) => load()),
                  ),
                );
              },
            ),
    );
  }
}

class StudentAssignmentDetail extends StatelessWidget{final dynamic assignment;const StudentAssignmentDetail({super.key,required this.assignment});
  Future<void> submit(BuildContext context)async{await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>_SubmitAssignmentSheet(assignment:assignment));}
  @override Widget build(BuildContext c)=>_Base(title:assignment['title']??'تکلیف',child:ListView(padding:const EdgeInsets.all(16),children:[Text(assignment['description']??'متنی برای تکلیف ثبت نشده',style:const TextStyle(fontSize:16)),const SizedBox(height:12),Text('مهلت: ${assignment['due_date']??'بدون مهلت'}'),Text('نمره کل: ${assignment['max_score']??20}'),if(assignment['latest_status']=='resubmit_requested')const Padding(padding:EdgeInsets.symmetric(vertical:10),child:Text('استاد این تکلیف را نپذیرفته؛ لطفاً اصلاح و دوباره ارسال کنید.',style:TextStyle(color:Colors.orangeAccent,fontWeight:FontWeight.bold))),const SizedBox(height:12),AssignmentMediaList(attachments:assignment['attachments']??[]),const SizedBox(height:20),FilledButton.icon(onPressed:()=>submit(c),icon:const Icon(Icons.upload_rounded),label:Text(assignment['latest_status']=='resubmit_requested'?'اصلاح و ارسال مجدد':assignment['submitted']!=null && (int.tryParse('${assignment['submitted']}')??0)>0?'تکلیف ارسال شده':'ارسال تکلیف'))]));
}

class _SubmitAssignmentSheet extends StatefulWidget{final dynamic assignment;const _SubmitAssignmentSheet({required this.assignment});@override State<_SubmitAssignmentSheet>createState()=>_SubmitAssignmentSheetState();}
class _SubmitAssignmentSheetState extends State<_SubmitAssignmentSheet>{final text=TextEditingController();List<String>files=[];bool saving=false;
  Future<void> send()async{setState(()=>saving=true);final r=await ApiService.uploadMultipartMany('student/submit-assignment',{'assignment_id':'${widget.assignment['id']}','content':text.text.trim()},filePaths:files);if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??(r['success']==true?'تکلیف ارسال شد':'خطا'))));if(r['success']==true)Navigator.pop(context);}}
  @override Widget build(BuildContext c)=>SafeArea(child: Container(decoration:BoxDecoration(color:const Color(0xFF08271F),borderRadius:const BorderRadius.vertical(top:Radius.circular(28))),padding:EdgeInsets.only(left:18,right:18,top:18,bottom:MediaQuery.of(c).viewInsets.bottom+18),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('ارسال تکلیف',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),TextField(controller:text,maxLines:6,decoration:const InputDecoration(labelText:'نوشته / پاسخ')),const SizedBox(height:10),MediaPickerPanel(onChanged:(v)=>setState(()=>files=v)),const SizedBox(height:14),FilledButton(onPressed:saving?null:send,child:Text(saving?'در حال ارسال...':'ارسال نهایی'))]))));
}

class MyTeachersScreen extends StatefulWidget {
  MyTeachersScreen({super.key});

  @override
  State<MyTeachersScreen> createState() => _MyTeachersScreenState();
}

class _MyTeachersScreenState extends State<MyTeachersScreen> {
  List _items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiService.get('student/list-teachers');
    if (!mounted) return;
    setState(() {
      _items = r['success'] == true ? (r['data'] ?? []) : [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext c) {
    return _Base(
      title: 'استادهای من',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('استادی برای کلاس شما ثبت نشده است.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final x = _items[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: Text(x['full_name'] ?? ''),
                      ),
                    );
                  },
                ),
    );
  }
}

class MessagesScreen extends StatefulWidget{const MessagesScreen({super.key});@override State<MessagesScreen>createState()=>_MessagesScreenState();}
class _MessagesScreenState extends State<MessagesScreen>{List _items=[];bool loading=true;@override void initState(){super.initState();load();}Future<void>load()async{final r=await ApiService.get('messages/list-threads');if(mounted)setState(()=>{_items=r['success']==true?r['data']:[],loading=false});}Future<void>openThread(dynamic x)async{final id=x['id'];final r=await ApiService.get('messages/list?thread_id=$id');if(!mounted)return;final messages=r['success']==true?(r['data']??[]):[];showDialog(context:context,builder:(d)=>AlertDialog(title:Text('گفتگو با ${x['student_name']??x['teacher_name']??''}'),content:SizedBox(width:400,height:350,child:ListView(children:messages.map<Widget>((m)=>ListTile(title:Text(m['sender_role']=='teacher'?'معلم':'قرآن آموز'),subtitle:Text(m['content']??''))).toList())),actions:[if(x['status']!='allowed')TextButton(onPressed:()async{final rr=await ApiService.post('messages/allow-continue',{'thread_id':id},auth:true);if(d.mounted)Navigator.pop(d);if(rr['success']==true)load();},child:const Text('اجازه ادامه')) ,TextButton(onPressed:()=>Navigator.pop(d),child:const Text('بستن'))]));}
@override Widget build(BuildContext c)=>_Base(title:'پیام‌ها',child:loading?const Center(child:CircularProgressIndicator()):ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final x=_items[i];return Card(child:ListTile(title:Text(x['student_name']??x['teacher_name']??'گفتگو'),subtitle:Text('وضعیت: ${x['status']}'),onTap:()=>openThread(x)));}));}
